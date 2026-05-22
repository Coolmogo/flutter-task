import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/auth/auth_controller.dart';
import 'package:task_manager_flutter/core/tasks/domain/task_activity_model.dart';
import 'package:task_manager_flutter/core/tasks/domain/task_model.dart';
import 'package:task_manager_flutter/core/tasks/service/task_service.dart';
import 'package:task_manager_flutter/core/users/domain/user_model.dart';
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

    String newTaskId;
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
      newTaskId = 'TASK-${nextNum.toString().padLeft(2, '0')}';
    } else {
      final projects = ref.read(projectListProvider).value ?? [];
      final project = projects.firstWhere(
        (item) => item.id == projectId,
        orElse: () => const Project(id: '', title: '', projectCode: 'TASK'),
      );
      final code = project.projectCode.isNotEmpty
          ? project.projectCode
          : 'TASK';

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
      newTaskId = '$code-$nextNum';
    }

    final newTask = Task(
      id: newTaskId,
      title: title,
      description: description,
      projectId: projectId,
      stageId: stageId,
      status: initialStatus,
      assignee: assignee,
      dueDate: dueDate,
    );

    final updated = [...currentTasks, newTask];
    await ref.read(taskServiceProvider).saveTasks(updated);
    state = AsyncValue.data(updated);
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

    final updated = currentTasks.map<Task>((task) {
      if (task.id != taskId) {
        return task;
      }

      final internalAuditTrail = [...task.activities];
      final normalizedExistingDescription = _normalizeDescription(
        task.description,
      );
      final normalizedIncomingDescription = clearDescription
          ? null
          : _normalizeDescription(description);
      final shouldUpdateDescription = clearDescription || description != null;

      if (title != null && title != task.title) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.updated,
            field: 'title',
            oldValue: task.title,
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

      if (clearDueDate && task.dueDate != null) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.removed,
            field: 'dueDate',
            oldValue: task.dueDate?.toIso8601String(),
          ),
        );
      } else if (dueDate != null && dueDate != task.dueDate) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.updated,
            field: 'dueDate',
            oldValue: task.dueDate?.toIso8601String(),
            newValue: dueDate.toIso8601String(),
          ),
        );
      }

      if (clearAssignee && task.assignee != null) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.assigned,
            field: 'assignee',
            oldValue: task.assignee?.toJson(),
          ),
        );
      } else if (assignee != null && assignee.id != task.assignee?.id) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.assigned,
            field: 'assignee',
            oldValue: task.assignee?.toJson(),
            newValue: assignee.toJson(),
          ),
        );
      }

      if (status != null && status != task.status) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.moved,
            field: 'status',
            oldValue: task.status,
            newValue: status,
          ),
        );
      }

      if (stageId != null && stageId != task.stageId) {
        internalAuditTrail.add(
          _createHistoryLog(
            action: ActivityAction.moved,
            field: 'stageId',
            oldValue: task.stageId,
            newValue: stageId,
          ),
        );
      }

      return Task(
        id: task.id,
        title: title ?? task.title,
        description: shouldUpdateDescription
            ? normalizedIncomingDescription
            : task.description,
        status: status ?? task.status,
        stageId: stageId ?? task.stageId,
        projectId: projectId ?? task.projectId,
        dueDate: clearDueDate ? null : (dueDate ?? task.dueDate),
        assignee: clearAssignee ? null : (assignee ?? task.assignee),
        activities: internalAuditTrail,
      );
    }).toList();

    await ref.read(taskServiceProvider).saveTasks(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final updated = currentTasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      final nextStatus = task.status == 'Done' ? 'To Do' : 'Done';
      return task.copyWith(status: nextStatus);
    }).toList();

    await ref.read(taskServiceProvider).saveTasks(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> addComment(String taskId, String commentText) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final log = _createCommentLog(commentText);

    final updated = currentTasks.map<Task>((task) {
      if (task.id != taskId) {
        return task;
      }

      return task.copyWith(activities: [...task.activities, log]);
    }).toList();

    await ref.read(taskServiceProvider).saveTasks(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> moveTask({
    required String taskId,
    required String? toStageId,
    required String targetStatus,
  }) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final updated = currentTasks.map((task) {
      if (task.id != taskId) {
        return task;
      }

      return task.copyWith(stageId: toStageId, status: targetStatus);
    }).toList();

    await ref.read(taskServiceProvider).saveTasks(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> deleteTask(String taskId) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final updated = currentTasks.where((task) => task.id != taskId).toList();
    await ref.read(taskServiceProvider).saveTasks(updated);
    state = AsyncValue.data(updated);
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
}

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);
