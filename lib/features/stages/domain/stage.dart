import 'package:flutter/foundation.dart';
import '../../tasks/domain/task.dart';

@immutable
class Stage {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final List<Task> tasks;

  const Stage({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.tasks = const [],
  });

  Stage copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    List<Task>? tasks,
  }) {
    return Stage(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };

  factory Stage.fromJson(Map<String, dynamic> json) => Stage(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    tasks: (json['tasks'] as List).map((t) => Task.fromJson(t)).toList(),
  );
}
