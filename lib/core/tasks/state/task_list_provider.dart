import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/auth/auth_controller.dart';
import 'package:task_manager_flutter/core/tasks/domain/task_activity_model.dart';
import 'package:task_manager_flutter/core/tasks/domain/task_model.dart';
import 'package:task_manager_flutter/core/tasks/service/task_service.dart';
import 'package:task_manager_flutter/core/users/domain/user_model.dart';
import 'package:task_manager_flutter/environment/environment.dart';
import 'package:task_manager_flutter/features/projects/domain/project_model.dart';
import 'package:task_manager_flutter/features/projects/state/project_list_provider.dart';

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  FutureOr<List<Task>> build() {
    return ref.read(taskServiceProvider).loadTasks();
  }

  ActivityLog _createCommentLog(String text) {
    final currentUser = ref.read(authProvider);
    return ActivityLog(
      id: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      author: currentUser,
      timestamp: DateTime.now(),
      type: ActivityType.comment,
      action: ActivityAction.commented,
    );
  }

  ActivityLog _createHistoryLog({
    required ActivityAction action,
    required String field,
    Object? oldValue,
    Object? newValue,
  }) {
    final currentUser = ref.read(authProvider);
    return ActivityLog(
      id: 'ACT-${DateTime.now().microsecondsSinceEpoch}',
      author: currentUser,
      timestamp: DateTime.now(),
      type: ActivityType.history,
      action: action,
      field: field,
      oldValue: oldValue,
      newValue: newValue,
    );
  }

  String? _normalizeDescription(String? value) {
    if (value == null) return null;

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> addTask({
    required String title,
    String? description,
    String? projectId,
    String? stageId,
    String initialStatus = 'To Do',
    User? assignee,
    DateTime? dueDate,
  }) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    try {
      final newTask = Task(
        id: _buildNextTaskId(currentTasks, projectId),
        title: title,
        description: description,
        source: projectId == null || projectId.isEmpty
            ? TaskSource.issue
            : TaskSource.project,
        projectId: projectId,
        stageId: stageId,
        status: initialStatus,
        assignee: assignee,
        dueDate: dueDate,
      );

      final createdTask = await ref.read(taskServiceProvider).createTask(newTask);
      state = AsyncValue.data([...currentTasks, createdTask]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    DateTime? dueDate,
    User? assignee,
    String? status,
    String? stageId,
    String? projectId,
    bool clearDueDate = false,
    bool clearDescription = false,
    bool clearAssignee = false,
  }) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    Task? existingTask;
    for (final task in currentTasks) {
      if (task.id == taskId) {
        existingTask = task;
        break;
      }
    }
    if (existingTask == null) {
      state = AsyncValue.data(currentTasks);
      return;
    }

    try {
      final internalAuditTrail = [...existingTask.activities];
      final normalizedExistingDescription = _normalizeDescription(
        existingTask.description,
      );
      final normalizedIncomingDescription = clearDescription
          ? null
          : _normalizeDescription(description);
      final shouldUpdateDescription = clearDescription || description != null;

      if (title != null && title != existingTask.title) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.updated,
            field: 'title',
            oldValue: existingTask.title,
            newValue: title,
          ),
        );
      }

      if (shouldUpdateDescription &&
          normalizedIncomingDescription != normalizedExistingDescription) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.updated,
            field: 'description',
            oldValue: normalizedExistingDescription,
            newValue: normalizedIncomingDescription,
          ),
        );
      }

      if (clearDueDate && existingTask.dueDate != null) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.removed,
            field: 'dueDate',
            oldValue: existingTask.dueDate?.toIso8601String(),
          ),
        );
      } else if (dueDate != null && dueDate != existingTask.dueDate) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.updated,
            field: 'dueDate',
            oldValue: existingTask.dueDate?.toIso8601String(),
            newValue: dueDate.toIso8601String(),
          ),
        );
      }

      if (clearAssignee && existingTask.assignee != null) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.assigned,
            field: 'assignee',
            oldValue: existingTask.assignee?.toJson(),
          ),
        );
      } else if (assignee != null && assignee.id != existingTask.assignee?.id) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.assigned,
            field: 'assignee',
            oldValue: existingTask.assignee?.toJson(),
            newValue: assignee.toJson(),
          ),
        );
      }

      if (status != null && status != existingTask.status) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.moved,
            field: 'status',
            oldValue: existingTask.status,
            newValue: status,
          ),
        );
      }

      if (stageId != null && stageId != existingTask.stageId) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.moved,
            field: 'stageId',
            oldValue: existingTask.stageId,
            newValue: stageId,
          ),
        );
      }

      final updatedTask = Task(
        id: existingTask.id,
        title: title ?? existingTask.title,
        description: shouldUpdateDescription
            ? normalizedIncomingDescription
            : existingTask.description,
        dueDate: clearDueDate ? null : (dueDate ?? existingTask.dueDate),
        assignee: clearAssignee ? null : (assignee ?? existingTask.assignee),
        status: status ?? existingTask.status,
        source: existingTask.source,
        projectId: projectId ?? existingTask.projectId,
        stageId: stageId ?? existingTask.stageId,
        activities: internalAuditTrail,
      );

      final service = ref.read(taskServiceProvider);
      final persistedTask = await service.updateTask(
        updatedTask,
        clearDueDate: clearDueDate,
        clearAssignee: clearAssignee,
      );
      final activities = Environment().config.useMockData
          ? internalAuditTrail
          : await service.loadTaskActivity(taskId);
      final finalTask = Task(
        id: persistedTask.id,
        title: persistedTask.title,
        description: persistedTask.description,
        dueDate: updatedTask.dueDate,
        assignee: updatedTask.assignee ?? persistedTask.assignee,
        status: persistedTask.status,
        source: updatedTask.source,
        projectId: updatedTask.projectId,
        stageId: persistedTask.stageId ?? updatedTask.stageId,
        activities: activities,
      );

      final updatedTasks = currentTasks
          .map((task) => task.id == taskId ? finalTask : task)
          .toList();
      state = AsyncValue.data(updatedTasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final task = findTaskById(taskId);
    if (task == null || task.id.isEmpty) {
      return;
    }

    final nextStatus = task.status == 'Done' ? 'To Do' : 'Done';
    await updateTask(taskId, status: nextStatus);
  }

  Future<void> addComment(String taskId, String commentText) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final service = ref.read(taskServiceProvider);
      final log = Environment().config.useMockData
          ? _createCommentLog(commentText)
          : await service.addComment(taskId, commentText);
      final taskActivities = Environment().config.useMockData
          ? null
          : await service.loadTaskActivity(taskId);

      final updated = currentTasks.map<Task>((task) {
        if (task.id != taskId) {
          return task;
        }

        return task.copyWith(
          activities: taskActivities ?? [...task.activities, log],
        );
      }).toList();

      if (Environment().config.useMockData) {
        final commentedTask = updated.firstWhere((task) => task.id == taskId);
        await service.updateTask(commentedTask);
      }

      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> moveTask({
    required String taskId,
    required String? toStageId,
    required String targetStatus,
  }) async {
    await updateTask(
      taskId,
      stageId: toStageId,
      status: targetStatus,
    );
  }

  Future<void> deleteTask(String taskId) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    try {
      await ref.read(taskServiceProvider).deleteTask(taskId);
      final updated = currentTasks.where((task) => task.id != taskId).toList();
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Task? findTaskById(String taskId) {
    if (state.value == null) {
      return null;
    }

    return state.value!.firstWhere(
      (task) => task.id == taskId,
      orElse: () => const Task(id: '', title: ''),
    );
  }

  Future<void> refreshTaskDetails(String taskId) async {
    final currentTasks = state.value ?? [];
    if (Environment().config.useMockData) {
      return;
    }

    try {
      final activities = await ref.read(taskServiceProvider).loadTaskActivity(taskId);
      final updated = currentTasks.map((task) {
        if (task.id != taskId) {
          return task;
        }

        return task.copyWith(activities: activities);
      }).toList();
      state = AsyncValue.data(updated);
    } catch (_) {
      state = AsyncValue.data(currentTasks);
    }
  }

  String _buildNextTaskId(List<Task> currentTasks, String? projectId) {
    if (!Environment().config.useMockData) {
      return DateTime.now().microsecondsSinceEpoch.toString();
    }

    if (projectId == null || projectId.isEmpty) {
      var nextNum = 1;
      for (final task in currentTasks) {
        if (task.projectId == null || task.projectId!.isEmpty) {
          final parts = task.id.split('-');
          if (parts.length > 1) {
            final parsed = int.tryParse(parts[parts.length - 1]);
            if (parsed != null && parsed >= nextNum) {
              nextNum = parsed + 1;
            }
          }
        }
      }
      return 'TASK-${nextNum.toString().padLeft(2, '0')}';
    }

    final projects = ref.read(projectListProvider).value ?? [];
    final project = projects.firstWhere(
      (item) => item.id == projectId,
      orElse: () => const Project(id: '', title: '', projectCode: 'TASK'),
    );
    final code = project.projectCode.isNotEmpty ? project.projectCode : 'TASK';

    var nextNum = 1;
    for (final task in currentTasks) {
      if (task.projectId == projectId) {
        final parts = task.id.split('-');
        if (parts.length > 1) {
          final parsed = int.tryParse(parts[parts.length - 1]);
          if (parsed != null && parsed >= nextNum) {
            nextNum = parsed + 1;
          }
        }
      }
    }
    return '$code-$nextNum';
  }
}

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);
