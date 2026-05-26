import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/core/http/api_exception.dart';
import 'package:task_manager_flutter/core/http/http_client.dart';
import 'package:task_manager_flutter/core/tasks/domain/task_activity_model.dart';
import 'package:task_manager_flutter/core/tasks/domain/task_model.dart';
import 'package:task_manager_flutter/environment/environment.dart';

abstract class TaskService {
  Future<List<Task>> loadTasks();
  Future<Task> createTask(Task task);
  Future<Task> updateTask(
    Task task, {
    bool clearDueDate = false,
    bool clearAssignee = false,
  });
  Future<void> deleteTask(String taskId);
  Future<List<ActivityLog>> loadTaskActivity(String taskId);
  Future<ActivityLog> addComment(String taskId, String text);
}

class LocalTaskService implements TaskService {
  static const _storageKey = 'taskflow_global_tasks_v1';

  const LocalTaskService();

  @override
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return _loadMockTasks();
      }
    }

    return _loadMockTasks();
  }

  @override
  Future<Task> createTask(Task task) async {
    final tasks = await loadTasks();
    await _saveAllTasks([...tasks, task]);
    return task;
  }

  @override
  Future<Task> updateTask(
    Task task, {
    bool clearDueDate = false,
    bool clearAssignee = false,
  }) async {
    final tasks = await loadTasks();
    final updated = tasks.map((item) => item.id == task.id ? task : item).toList();
    await _saveAllTasks(updated);
    return task;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final tasks = await loadTasks();
    final updated = tasks.where((task) => task.id != taskId).toList();
    await _saveAllTasks(updated);
  }

  @override
  Future<List<ActivityLog>> loadTaskActivity(String taskId) async {
    final tasks = await loadTasks();
    final task = tasks.firstWhere(
      (item) => item.id == taskId,
      orElse: () => const Task(id: '', title: ''),
    );
    return task.activities;
  }

  @override
  Future<ActivityLog> addComment(String taskId, String text) async {
    final log = ActivityLog(
      id: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      timestamp: DateTime.now(),
      type: ActivityType.comment,
      action: ActivityAction.commented,
    );
    final tasks = await loadTasks();
    final updated = tasks.map((task) {
      if (task.id != taskId) {
        return task;
      }
      return task.copyWith(activities: [...task.activities, log]);
    }).toList();
    await _saveAllTasks(updated);
    return log;
  }

  Future<void> _saveAllTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<List<Task>> _loadMockTasks() async {
    final jsonString = await rootBundle.loadString('mock/data/tasks.json');
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class HttpTaskService implements TaskService {
  final Dio _dio;

  HttpTaskService({required String apiBaseUrl, required Ref ref})
    : _dio = buildHttpClient(
        baseUrl: '$apiBaseUrl/tasks',
        ref: ref,
      );

  @override
  Future<List<Task>> loadTasks() async {
    try {
      final response = await _dio.get<List<dynamic>>('');
      final data = response.data;

      if (data == null) {
        throw ApiException.invalidResponse('The tasks response was empty.');
      }

      return data
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw ApiException.invalidResponse(
                'Each task item must be a JSON object.',
              );
            }

            return Task.fromBackendJson(item);
          })
          .toList();
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }

      throw ApiException.fromDioException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.invalidResponse();
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    final assigneeId = _parseOptionalInt(
      value: task.assignee?.id,
      fieldName: 'assignee',
      message:
          'Assignee editing needs backend user ids before it can be saved.',
    );

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '',
        data: {
          'title': task.title,
          'description': task.description,
          'status': Task.backendStatusFromUi(task.status),
          'assignee_id': assigneeId,
          'stage_id': task.stageId,
          'due': task.dueDate == null ? null : _formatDate(task.dueDate!),
        },
      );

      final data = response.data;
      if (data == null) {
        throw ApiException.invalidResponse('The task create response was empty.');
      }

      return Task.fromBackendJson(data);
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }

      throw ApiException.fromDioException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.invalidResponse();
    }
  }

  @override
  Future<Task> updateTask(
    Task task, {
    bool clearDueDate = false,
    bool clearAssignee = false,
  }) async {
    final taskId = int.tryParse(task.id);
    if (taskId == null) {
      throw const ApiException('Task id must be numeric for backend updates.');
    }

    final assigneeId = clearAssignee
        ? null
        : _parseOptionalInt(
            value: task.assignee?.id,
            fieldName: 'assignee',
            message:
                'Assignee editing needs backend user ids before it can be saved.',
          );

    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/$taskId',
        data: {
          'title': task.title,
          'description': task.description,
          'status': Task.backendStatusFromUi(task.status),
          'assignee_id': assigneeId,
          'stage_id': task.stageId,
          'due': clearDueDate
              ? null
              : (task.dueDate == null ? null : _formatDate(task.dueDate!)),
        },
      );

      final data = response.data;
      if (data == null) {
        throw ApiException.invalidResponse('The task update response was empty.');
      }

      return Task.fromBackendJson(data);
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }

      throw ApiException.fromDioException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.invalidResponse();
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final parsedTaskId = int.tryParse(taskId);
    if (parsedTaskId == null) {
      throw const ApiException('Task id must be numeric for backend deletes.');
    }

    try {
      await _dio.delete<void>('/$parsedTaskId');
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }

      throw ApiException.fromDioException(error);
    }
  }

  @override
  Future<List<ActivityLog>> loadTaskActivity(String taskId) async {
    final parsedTaskId = int.tryParse(taskId);
    if (parsedTaskId == null) {
      throw const ApiException('Task id must be numeric for backend activity.');
    }

    try {
      final responses = await Future.wait([
        _dio.get<List<dynamic>>('/$parsedTaskId/comments'),
        _dio.get<List<dynamic>>('/$parsedTaskId/activities'),
      ]);

      final comments = responses[0].data ?? const <dynamic>[];
      final activities = responses[1].data ?? const <dynamic>[];

      final merged = <ActivityLog>[
        ...comments.whereType<Map<String, dynamic>>().map(
          ActivityLog.fromBackendCommentJson,
        ),
        ...activities.whereType<Map<String, dynamic>>().map(
          ActivityLog.fromBackendActivityJson,
        ),
      ];
      merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return merged;
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }

      throw ApiException.fromDioException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.invalidResponse();
    }
  }

  @override
  Future<ActivityLog> addComment(String taskId, String text) async {
    final parsedTaskId = int.tryParse(taskId);
    if (parsedTaskId == null) {
      throw const ApiException('Task id must be numeric for backend comments.');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/$parsedTaskId/comments',
        data: {'text': text},
      );

      final data = response.data;
      if (data == null) {
        throw ApiException.invalidResponse('The comment response was empty.');
      }

      return ActivityLog.fromBackendCommentJson(data);
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }

      throw ApiException.fromDioException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.invalidResponse();
    }
  }

  int? _parseOptionalInt({
    required String? value,
    required String fieldName,
    required String message,
  }) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw ApiException('$message Missing $fieldName id.');
    }
    return parsed;
  }

  String _formatDate(DateTime value) {
    return value.toIso8601String().split('T').first;
  }
}

final taskServiceProvider = Provider<TaskService>((ref) {
  final environment = Environment().config;

  if (environment.useMockData) {
    return const LocalTaskService();
  }

  return HttpTaskService(apiBaseUrl: environment.apiBaseUrl, ref: ref);
});
