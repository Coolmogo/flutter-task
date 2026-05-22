import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/core/tasks/domain/task_model.dart';
import 'package:task_manager_flutter/environment/environment.dart';

abstract class TaskService {
  Future<List<Task>> loadTasks();
  Future<void> saveTasks(List<Task> tasks);
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
  Future<void> saveTasks(List<Task> tasks) async {
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

final taskServiceProvider = Provider<TaskService>((ref) {
  final environment = Environment().config;

  if (environment.useMockData) {
    return const LocalTaskService();
  }

  return const LocalTaskService();
});
