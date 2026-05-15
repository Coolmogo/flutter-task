import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/project.dart';
import '../../stages/domain/stage.dart';
import '../../tasks/domain/task.dart';
import '../../users/domain/user.dart';
import '../../auth/project_auth_controller.dart';

const List<User> sampleUsers = [
  User(id: 'john', name: 'John Robert', email: 'john@sample.com'),
  User(id: 'james', name: 'James Albert', email: 'james@sample.com'),
];

final teamProvider = Provider<List<User>>((ref) => sampleUsers);

class ProjectListNotifier extends Notifier<List<Project>> {
  static const _storageKey = 'taskflow_data_v1';

  @override
  List<Project> build() {
    _loadFromStorage();
    return [];
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        state = decoded.map((item) => Project.fromJson(item)).toList();
      } catch (e) {
        debugPrint("Error decoding stored projects: $e");
        state = _getInitialData();
      }
    } else {
      state = _getInitialData();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(state.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  @override
  set state(List<Project> value) {
    super.state = value;
    _saveToStorage();
  }

  List<Project> _getInitialData() {
    final john = sampleUsers[0];
    final james = sampleUsers[1];

    return [
      Project(
        id: 'PRJ-1042',
        title: 'Customer Support Portal Redesign',
        description:
            'Redesign and modernize the customer support portal to improve user experience, reduce ticket resolution time, and add self-service capabilities such as knowledge base search and live chat integration.',
        stages: [
          Stage(
            id: 'STG-001',
            title: 'To-do',
            description:
                'Gather business requirements, conduct stakeholder interviews, and define project scope.',
            dueDate: DateTime.now().add(const Duration(days: 7)),
            tasks: [
              Task(
                id: 'TASK-301',
                title: 'Define Data Models',
                description: 'Create Project, Stage, and Task classes',
                dueDate: DateTime.now().add(const Duration(days: 2)),
                status: 'Discovery & Requirements',
                assignee: john,
                comments: [
                  'Almost done with the User model!',
                  'Started the Task model.',
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  void toggleTaskStatus(String projectId, String stageId, String taskId) {
    state = [
      for (final project in state)
        if (project.id == projectId)
          project.copyWith(
            stages: [
              for (final stage in project.stages)
                if (stage.id == stageId)
                  stage.copyWith(
                    tasks: [
                      for (final task in stage.tasks)
                        if (task.id == taskId)
                          task.copyWith(
                            status: task.status == 'Completed'
                                ? 'In Progress'
                                : 'Completed',
                          )
                        else
                          task,
                    ],
                  )
                else
                  stage,
            ],
          )
        else
          project,
    ];
  }

  void addComment(
    String projectId,
    String stageId,
    String taskId,
    String comment,
  ) {
    state = [
      for (final project in state)
        if (project.id == projectId)
          project.copyWith(
            stages: [
              for (final stage in project.stages)
                if (stage.id == stageId)
                  stage.copyWith(
                    tasks: [
                      for (final task in stage.tasks)
                        if (task.id == taskId)
                          task.copyWith(comments: [...task.comments, comment])
                        else
                          task,
                    ],
                  )
                else
                  stage,
            ],
          )
        else
          project,
    ];
  }

  void addProject(String title, String description) {
    final newProject = Project(
      id: 'PRJ-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      stages: [],
    );
    state = [...state, newProject];
  }

  void moveTask({
    required String projectId,
    required String fromStageId,
    required String toStageId,
    required String taskId,
  }) {
    state = [
      for (final project in state)
        if (project.id == projectId)
          project.copyWith(
            stages: [
              for (final stage in project.stages)
                if (stage.id == fromStageId)
                  stage.copyWith(
                    tasks: stage.tasks.where((t) => t.id != taskId).toList(),
                  )
                else if (stage.id == toStageId)
                  stage.copyWith(
                    tasks: [
                      ...stage.tasks,
                      project.stages
                          .firstWhere((s) => s.id == fromStageId)
                          .tasks
                          .firstWhere((t) => t.id == taskId)
                          .copyWith(status: stage.title),
                    ],
                  )
                else
                  stage,
            ],
          )
        else
          project,
    ];
  }

  void addStage(String projectId, String stageTitle) {
    state = [
      for (final project in state)
        if (project.id == projectId)
          project.copyWith(
            stages: [
              ...project.stages,
              Stage(
                id: 'STG-${DateTime.now().millisecondsSinceEpoch}',
                title: stageTitle,
                tasks: [],
              ),
            ],
          )
        else
          project,
    ];
  }

  void updateTask(
    String projectId,
    String stageId,
    String taskId, {
    String? title,
    String? description,
    DateTime? dueDate,
    User? assignee,
  }) {
    state = [
      for (final project in state)
        if (project.id == projectId)
          project.copyWith(
            stages: [
              for (final stage in project.stages)
                if (stage.id == stageId)
                  stage.copyWith(
                    tasks: [
                      for (final task in stage.tasks)
                        if (task.id == taskId)
                          task.copyWith(
                            title: title ?? task.title,
                            description: description ?? task.description,
                            dueDate: dueDate ?? task.dueDate,
                            assignee: assignee ?? task.assignee,
                          )
                        else
                          task,
                    ],
                  )
                else
                  stage,
            ],
          )
        else
          project,
    ];
  }

  void addTask(String projectId, String stageId, String taskTitle) {
    state = [
      for (final project in state)
        if (projectId == project.id)
          project.copyWith(
            stages: [
              for (final stage in project.stages)
                if (stageId == stage.id)
                  stage.copyWith(
                    tasks: [
                      ...stage.tasks,
                      Task(
                        id: 'TASK-${DateTime.now().millisecondsSinceEpoch}',
                        title: taskTitle,
                        status: stage.title,
                      ),
                    ],
                  )
                else
                  stage,
            ],
          )
        else
          project,
    ];
  }

  void deleteTask(String projectId, String stageId, String taskId) {
    state = [
      for (final project in state)
        if (projectId == project.id)
          project.copyWith(
            stages: [
              for (final stage in project.stages)
                if (stageId == stage.id)
                  stage.copyWith(
                    tasks: stage.tasks.where((t) => t.id != taskId).toList(),
                  )
                else
                  stage,
            ],
          )
        else
          project,
    ];
  }
}

final projectListProvider =
    NotifierProvider<ProjectListNotifier, List<Project>>(() {
      return ProjectListNotifier();
    });

final myTasksProvider = Provider<List<Task>>((ref) {
  final currentUser = ref.watch(authProvider);
  final allProjects = ref.watch(projectListProvider);

  if (currentUser == null) return [];

  List<Task> myTasks = [];
  for (var project in allProjects) {
    for (var stage in project.stages) {
      final tasksForMe = stage.tasks.where(
        (task) => task.assignee?.id == currentUser.id,
      );
      myTasks.addAll(tasksForMe);
    }
  }
  return myTasks;
});
