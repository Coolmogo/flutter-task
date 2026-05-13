import 'package:flutter/foundation.dart';
import '../../users/domain/user.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime dueDate;
  final String status;
  final User assignee;
  final List<String> comments;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.dueDate,
    this.status = 'pending',
    required this.assignee,
    this.comments = const [],
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? dueDate,
    String? status,
    User? assignee,
    List<String>? comments,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      comments: comments ?? this.comments,
    );
  }
}
