import '../../../users/model/user_model.dart';
import 'task_activity_model.dart';

enum TaskSource { project, issue }

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final User? assignee;
  final String status;
  final TaskSource source;
  final String? projectId;
  final String? stageId;
  final List<ActivityLog> activities;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.assignee,
    this.status = 'To Do',
    this.source = TaskSource.issue,
    this.projectId,
    this.stageId,
    this.activities = const [],
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    User? assignee,
    String? status,
    TaskSource? source,
    String? projectId,
    String? stageId,
    List<ActivityLog>? activities,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      source: source ?? this.source,
      projectId: projectId ?? this.projectId,
      stageId: stageId ?? this.stageId,
      activities: activities ?? this.activities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'assignee': assignee?.toJson(),
      'status': status,
      'source': source.name,
      'projectId': projectId,
      'stageId': stageId,
      'activities': activities.map((e) => e.toJson()).toList(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final projectId = json['projectId'] as String?;
    final sourceName = json['source'] as String?;

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      assignee: json['assignee'] != null
          ? User.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'To Do',
      source: TaskSource.values.firstWhere(
        (value) => value.name == sourceName,
        orElse: () {
          if (projectId != null && projectId.isNotEmpty) {
            return TaskSource.project;
          }

          return TaskSource.issue;
        },
      ),
      projectId: projectId,
      stageId: json['stageId'] as String?,
      activities: (json['activities'] as List<dynamic>?)
              ?.map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  factory Task.fromBackendJson(Map<String, dynamic> json) {
    final projectIdValue = json['project_id'];
    final stageValue = json['stage_id'] ?? json['stage'];
    final assigneeIdValue = json['assignee_id'];
    final assigneeJson = json['assignee'];
    final dueValue = json['due'] ?? json['due_date'] ?? json['end_date'];

    User? assignee;
    if (assigneeJson is Map<String, dynamic>) {
      assignee = User.fromJson(assigneeJson);
    } else if (assigneeIdValue != null) {
      assignee = User(
        id: assigneeIdValue.toString(),
        name: 'User #${assigneeIdValue.toString()}',
      );
    }

    return Task(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: dueValue != null
          ? DateTime.parse(dueValue as String)
          : null,
      assignee: assignee,
      status: (json['status'] as String?) ?? 'To Do',
      source: projectIdValue != null ? TaskSource.project : TaskSource.issue,
      projectId: projectIdValue?.toString(),
      stageId: stageValue?.toString(),
      activities: const [],
    );
  }

  static String backendStatusFromUi(String? status) {
    return (status == null || status.trim().isEmpty) ? 'To Do' : status.trim();
  }
}
