import 'package:flutter/foundation.dart';
import '../../users/domain/user.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final User? assignee;
  final DateTime? dueDate;
  final String status;
  final List<String> comments;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.assignee,
    this.dueDate,
    this.status = 'To Do',
    this.comments = const [],
  });

  Task copyWith({
    String? title,
    String? description,
    User? assignee,
    DateTime? dueDate,
    String? status,
    List<String>? comments,
  }) {
    return Task(
      id: id, // ID never changes
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'assignee': assignee?.toJson(),
    'dueDate': dueDate?.toIso8601String(),
    'status': status,
    'comments': comments,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    assignee: json['assignee'] != null ? User.fromJson(json['assignee']) : null,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    status: json['status'] ?? 'To Do',
    comments: List<String>.from(json['comments'] ?? []),
  );
}
