import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/environment/environment.dart';
import 'package:task_manager_flutter/features/projects/domain/project_model.dart';

abstract class ProjectService {
  Future<List<Project>> loadProjects();
  Future<void> saveProjects(List<Project> projects);
}

class LocalProjectService implements ProjectService {
  static const _storageKey = 'taskflow_projects_data_v1';

  const LocalProjectService();

  @override
  Future<List<Project>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((item) => Project.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return _loadMockProjects();
      }
    }

    return _loadMockProjects();
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      projects.map((project) => project.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<List<Project>> _loadMockProjects() async {
    final jsonString = await rootBundle.loadString('mock/data/projects.json');
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((item) => Project.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

final projectServiceProvider = Provider<ProjectService>((ref) {
  final environment = Environment().config;

  if (environment.useMockData) {
    return const LocalProjectService();
  }

  return const LocalProjectService();
});
