import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/features/projects/domain/project_model.dart';
import 'package:task_manager_flutter/features/projects/domain/stage_model.dart';
import 'package:task_manager_flutter/features/projects/service/project_service.dart';

class ProjectListNotifier extends AsyncNotifier<List<Project>> {
  @override
  FutureOr<List<Project>> build() {
    return ref.read(projectServiceProvider).loadProjects();
  }

  Future<void> addProject(
    String title,
    String description,
    String projectCode,
  ) async {
    final currentProjects = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 400));

    var nextNum = 1;
    for (final project in currentProjects) {
      final parts = project.id.split('-');
      if (parts.length > 1) {
        final parsed = int.tryParse(parts[1]);
        if (parsed != null && parsed >= nextNum) {
          nextNum = parsed + 1;
        }
      }
    }

    final formattedNum = nextNum.toString().padLeft(2, '0');
    final newProject = Project(
      id: 'PRJ-$formattedNum',
      projectCode: projectCode,
      title: title,
      description: description,
      stages: [
        Stage(
          id: 'STG-01',
          title: 'Stage 0',
          description: 'Default entry workflow sprint container.',
          dueDate: DateTime.now().add(const Duration(days: 14)),
        ),
      ],
    );

    final updated = [...currentProjects, newProject];
    await ref.read(projectServiceProvider).saveProjects(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> addStage(String projectId, String stageTitle) async {
    final currentProjects = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final updated = currentProjects.map((project) {
      if (project.id != projectId) {
        return project;
      }

      var nextNum = 1;
      for (final stage in project.stages) {
        final parts = stage.id.split('-');
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
    }).toList();

    await ref.read(projectServiceProvider).saveProjects(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> updateStageStatuses(
    String projectId,
    String stageId,
    List<String> newStatuses,
  ) async {
    final currentProjects = state.value ?? [];
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final updated = currentProjects.map((project) {
      if (project.id != projectId) {
        return project;
      }

      return project.copyWith(
        stages: project.stages.map((stage) {
          if (stage.id != stageId) {
            return stage;
          }

          return stage.copyWith(statuses: newStatuses);
        }).toList(),
      );
    }).toList();

    await ref.read(projectServiceProvider).saveProjects(updated);
    state = AsyncValue.data(updated);
  }
}

final projectListProvider =
    AsyncNotifierProvider<ProjectListNotifier, List<Project>>(
      ProjectListNotifier.new,
    );
