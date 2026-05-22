import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/auth/auth_controller.dart';
import 'package:task_manager_flutter/core/tasks/domain/task_model.dart';
import 'package:task_manager_flutter/core/tasks/state/task_list_provider.dart';

export 'package:task_manager_flutter/core/tasks/state/task_list_provider.dart';

final myTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final currentUser = ref.watch(authProvider);
  final tasksAsync = ref.watch(taskListProvider);

  if (currentUser == null) return const AsyncValue.data([]);

  return tasksAsync.whenData((allTasks) {
    return allTasks.where((task) => task.assignee?.id == currentUser.id).toList();
  });
});
