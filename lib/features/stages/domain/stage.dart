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
}
