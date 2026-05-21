import '../../../users/model/user_model.dart';
import 'task_activity_model.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final User? assignee;
  final String status;
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
      'projectId': projectId,
      'stageId': stageId,
      'activities': activities.map((e) => e.toJson()).toList(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
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
      projectId: json['projectId'] as String?,
      stageId: json['stageId'] as String?,
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
