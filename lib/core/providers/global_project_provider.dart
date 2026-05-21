import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/projects/domain/project_model.dart';
import '../../features/projects/domain/stage_model.dart';
import '../users/model/user_model.dart';

Future<List<User>> _loadMockUsers() async {
  final jsonString = await rootBundle.loadString('mock/data/users.json');
  final List<dynamic> decoded = jsonDecode(jsonString);
  return decoded
      .map((item) => User.fromJson(item as Map<String, dynamic>))
      .toList();
}

Future<List<Project>> _loadMockProjects() async {
  final jsonString = await rootBundle.loadString('mock/data/projects.json');
  final List<dynamic> decoded = jsonDecode(jsonString);
  return decoded
      .map((item) => Project.fromJson(item as Map<String, dynamic>))
      .toList();
}

final teamProvider = FutureProvider<List<User>>((ref) => _loadMockUsers());

class ProjectListNotifier extends AsyncNotifier<List<Project>> {
  static const _storageKey = 'taskflow_projects_data_v1';

  @override
  FutureOr<List<Project>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded
            .map((item) => Project.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint("Error decoding stored projects: $e");
        return _loadMockProjects();
      }
    } else {
      return _loadMockProjects();
    }
  }

  Future<void> _saveToStorage(List<Project> currentList) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      currentList.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addProject(
    String title,
    String description,
    String projectCode,
  ) async {
    final currentProjects = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 400));

    int nextNum = 1;
    for (final p in currentProjects) {
      final parts = p.id.split('-');
      if (parts.length > 1) {
        final parsed = int.tryParse(parts[1]);
        if (parsed != null && parsed >= nextNum) {
          nextNum = parsed + 1;
        }
      }
    }
    final formattedNum = nextNum.toString().padLeft(2, '0');
    final newProjectId = 'PRJ-$formattedNum';

    final newProject = Project(
      id: newProjectId,
      projectCode: projectCode,
      title: title,
      description: description,
      stages: [
        Stage(
          id: 'STG-01',
          title:
              'Stage 0', // Ensures EVERY project starts with at least 1 stage automatically!
          description: 'Default entry workflow sprint container.',
          dueDate: DateTime.now().add(const Duration(days: 14)),
        ),
      ],
    );

    final updated = [...currentProjects, newProject];
    await _saveToStorage(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> addStage(String projectId, String stageTitle) async {
    final currentProjects = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 300));

    final updated = currentProjects.map((project) {
      if (project.id == projectId) {
        int nextNum = 1;
        for (final s in project.stages) {
          final parts = s.id.split('-');
          if (parts.length > 1) {
            final parsed = int.tryParse(parts[1]);
            if (parsed != null && parsed >= nextNum) {
              nextNum = parsed + 1;
            }
          }
        }
        final newStageId = 'STG-${nextNum.toString().padLeft(2, '0')}';
        return project.copyWith(
          stages: [
            ...project.stages,
            Stage(id: newStageId, title: stageTitle),
          ],
        );
      }
      return project;
    }).toList();

    await _saveToStorage(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> updateStageStatuses(
    String projectId,
    String stageId,
    List<String> newStatuses,
  ) async {
    final currentProjects = state.value ?? [];
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(milliseconds: 150));

    final updated = currentProjects.map((project) {
      if (project.id == projectId) {
        return project.copyWith(
          stages: project.stages.map((stage) {
            if (stage.id == stageId) {
              return stage.copyWith(statuses: newStatuses);
            }
            return stage;
          }).toList(),
        );
      }
      return project;
    }).toList();

    await _saveToStorage(updated);
    state = AsyncValue.data(updated);
  }
}

final projectListProvider =
    AsyncNotifierProvider<ProjectListNotifier, List<Project>>(() {
      return ProjectListNotifier();
    });
