import '../../../users/model/user_model.dart';

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
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      assignee: json['assignee'] != null ? User.fromJson(json['assignee'] as Map<String, dynamic>) : null,
      status: json['status'] as String? ?? 'To Do',
      projectId: json['projectId'] as String?,
      stageId: json['stageId'] as String?,
      activities: (json['activities'] as List<dynamic>?)?.map((e) => ActivityLog.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
    );
  }
}

class Comment {
  final String id;
  final String taskId;
  final String text;
  final String authorName;
  final DateTime createdAt;

  const Comment({required this.id, required this.taskId, required this.text, required this.authorName, required this.createdAt});

  Map<String, dynamic> toJson() {
    return {'id': id, 'taskId': taskId, 'text': text, 'authorName': authorName, 'createdAt': createdAt.toIso8601String()};
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      text: json['text'] as String,
      authorName: json['authorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum ActivityType { comment, history }

class ActivityLog {
  final String id;
  final String text;
  final String authorName;
  final DateTime timestamp;
  final ActivityType type;

  const ActivityLog({required this.id, required this.text, required this.authorName, required this.timestamp, required this.type});

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'authorName': authorName, 'timestamp': timestamp.toIso8601String(), 'type': type.name};
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      text: json['text'] as String,
      authorName: json['authorName'] as String? ?? 'System',
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ActivityType.values.byName(json['type'] as String? ?? 'comment'),
    );
  }
}

abstract class ActivityLogClass {
  final ActivityType type;

  const ActivityLogClass({required this.type});
}

class UpdateActivityLog extends ActivityLogClass {
  final String id;
  final String text;
  final User user;
  final DateTime timestamp;
  final Object? oldValue;
  final Object? newValue;

  const UpdateActivityLog({required this.id, required this.text, required this.user, required this.timestamp, super.type = ActivityType.history});
}
