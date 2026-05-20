import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'stage_model.dart';

@immutable
class Project {
  final String id;
  final String title;
  final String? description;
  final List<Stage> stages;

  const Project({
    required this.id,
    required this.title,
    this.description,
    this.stages = const [],
  });

  Project copyWith({String? title, String? description, List<Stage>? stages}) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      stages: stages ?? this.stages,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'stages': stages.map((s) => s.toJson()).toList(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    stages: (json['stages'] as List).map((s) => Stage.fromJson(s)).toList(),
  );
}
