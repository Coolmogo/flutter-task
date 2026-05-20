// lib/core/Tasks/State/task_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/domain/task_model.dart';
import '../../../core/auth/auth_controller.dart'; // Verify path fits your auth file
import '../../users/model/user_model.dart'; // Adjust path to User model if needed

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  static const _storageKey = 'taskflow_global_tasks_v1';

  @override
  FutureOr<List<Task>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map<Task>((item) => Task.fromJson(item)).toList();
      } catch (e) {
        debugPrint("Error decoding stored tasks data: $e");
        return _getInitialTasks();
      }
    } else {
      return _getInitialTasks();
    }
  }

  Future<void> _saveToStorage(List<Task> currentList) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      currentList.map((t) => t.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  //  FIXED: Changed the parameter type from 'String type' to 'ActivityType type'
  ActivityLog _createLog(String text, ActivityType type) {
    final currentUser = ref.read(authProvider);
    return ActivityLog(
      id: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      authorName: currentUser?.name ?? 'System',
      timestamp: DateTime.now(),
      type: type, // Now binds perfectly without any type conflicts!
    );
  }

  List<Task> _getInitialTasks() {
    return [
      Task(
        id: 'TASK-301',
        title: 'Define Data Models',
        description: 'Create Project, Stage, and Task classes',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        status: 'To Do',
        stageId: 'STG-001',
        projectId: 'PRJ-1042',
        activities: [
          ActivityLog(
            id: 'ACT-INIT-1',
            text: 'Started the Task model design setup.',
            authorName: 'John Robert',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            type: ActivityType.comment,
          ),
          ActivityLog(
            id: 'ACT-INIT-2',
            text: 'Created task container environment.',
            authorName: 'System',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            type: ActivityType.history,
          ),
        ],
      ),
    ];
  }

  // --- CRUD FUNCTIONS ---

  Future<void> addTask({
    required String title,
    String? description,
    String? projectId,
    String? stageId,
    String initialStatus = 'To Do',
  }) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));

    final newTask = Task(
      id: 'TASK-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      projectId: projectId,
      stageId: stageId,
      status: initialStatus,
    );

    final updated = [...currentTasks, newTask];
    await _saveToStorage(updated);
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
    bool clearAssignee = false,
  }) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));

    final updated = currentTasks.map<Task>((task) {
      if (task.id == taskId) {
        //  Clone the task's existing historical timeline activity array
        final List<ActivityLog> internalAuditTrail = [...task.activities];

        // 1. Audit Title Changes
        if (title != null && title != task.title) {
          internalAuditTrail.add(
            _createLog('Renamed title to "$title"', ActivityType.history),
          );
        }

        // 2. Audit Description Changes
        if (description != null && description != task.description) {
          internalAuditTrail.add(
            _createLog('Updated the task description.', ActivityType.history),
          );
        }

        // 3. Audit Due Date Changes
        if (clearDueDate && task.dueDate != null) {
          internalAuditTrail.add(
            _createLog('Removed the due date.', ActivityType.history),
          );
        } else if (dueDate != null && dueDate != task.dueDate) {
          final formattedDate =
              "${dueDate.day}/${dueDate.month}/${dueDate.year}";
          internalAuditTrail.add(
            _createLog(
              'Changed due date to $formattedDate',
              ActivityType.history,
            ),
          );
        }

        // 4. Audit Assignee Changes
        if (clearAssignee && task.assignee != null) {
          internalAuditTrail.add(
            _createLog('Removed assignee (Unassigned)', ActivityType.history),
          );
        } else if (assignee != null && assignee.id != task.assignee?.id) {
          internalAuditTrail.add(
            _createLog(
              'Assigned task to ${assignee.name}',
              ActivityType.history,
            ),
          );
        }

        // Return the fresh mutated task containing the new audit stamps
        return task.copyWith(
          title: title ?? task.title,
          description: description ?? task.description,
          status: status ?? task.status,
          stageId: stageId ?? task.stageId,
          projectId: projectId ?? task.projectId,
          dueDate: clearDueDate ? null : (dueDate ?? task.dueDate),
          assignee: clearAssignee ? null : (assignee ?? task.assignee),
          activities:
              internalAuditTrail, //  Binds updated history logs list right back here
        );
      }
      return task;
    }).toList();

    await _saveToStorage(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));

    final updated = currentTasks.map((task) {
      if (task.id == taskId) {
        final nextStatus = task.status == 'Done' ? 'To Do' : 'Done';
        return task.copyWith(status: nextStatus);
      }
      return task;
    }).toList();

    await _saveToStorage(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> addComment(String taskId, String commentText) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 100));

    //  FIXED: Removed 'taskId' from the arguments list here
    final log = _createLog(commentText, ActivityType.comment);

    final updated = currentTasks.map<Task>((task) {
      if (task.id == taskId) {
        return task.copyWith(activities: [...task.activities, log]);
      }
      return task;
    }).toList();

    await _saveToStorage(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> moveTask({
    required String taskId,
    required String? toStageId,
    required String targetStatus,
  }) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));

    final updated = currentTasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(stageId: toStageId, status: targetStatus);
      }
      return task;
    }).toList();

    await _saveToStorage(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> deleteTask(String taskId) async {
    final currentTasks = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 200));

    final updated = currentTasks.where((t) => t.id != taskId).toList();
    await _saveToStorage(updated);
    state = AsyncValue.data(updated);
  }

  Task? findTaskById(String taskId) {
    if (state.value == null) return null;
    return state.value!.firstWhere(
      (t) => t.id == taskId,
      orElse: () => const Task(id: '', title: ''),
    );
  }
}

// Global Providers
final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  () {
    return TaskListNotifier();
  },
);

final myTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final currentUser = ref.watch(authProvider);
  final tasksAsync = ref.watch(taskListProvider);

  if (currentUser == null) return const AsyncValue.data([]);

  return tasksAsync.whenData((allTasks) {
    return allTasks
        .where((task) => task.assignee?.id == currentUser.id)
        .toList();
  });
});
