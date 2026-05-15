import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/project.dart';
import '../../stages/domain/stage.dart';
import '../../tasks/domain/task.dart';
import '../../users/domain/user.dart';

const List<User> sampleUsers = [
  User(id: 'john', name: 'John Robert', email: 'john@sample.com'),
  User(id: 'james', name: 'James Albert', email: 'james@sample.com'),
];

final teamProvider = Provider<List<User>>((ref) => sampleUsers);

class ProjectListNotifier extends Notifier<List<Project>> {
  @override
  List<Project> build() {
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
            title: 'Discovery & Requirements',
            description:
                'Gather business requirements, conduct stakeholder interviews, and define project scope.',
            dueDate: DateTime.now().add(const Duration(days: 7)),
            tasks: [
              Task(
                id: 'TASK-301',
                title: 'Define Data Models',
                description: 'Create Project, Stage, and Task classes',
                dueDate: DateTime.now().add(const Duration(days: 2)),
                status: 'In Progress',
                assignee: john,
                comments: [
                  'Almost done with the User model!',
                  'Started the Task model.',
                ],
              ),
              Task(
                id: 'TASK-302',
                title: 'Frontend Development',
                description:
                    'Build the new customer support portal interface using React and implement responsive layouts for desktop and mobile devices.',
                dueDate: DateTime.now().add(const Duration(days: 5)),
                status: 'In Progress',
                assignee: james,
                comments: [
                  'Initial component structure completed. Waiting on finalized UI assets from design team.',
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
      id: DateTime.now().toString(),
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
                          .firstWhere((t) => t.id == taskId),
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
                id: DateTime.now().toString(),
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
