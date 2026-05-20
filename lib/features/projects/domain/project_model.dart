import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'stage_model.dart';

@immutable
class Project {
  final String id;
  final String title;
  final String? description;
  final String projectCode;
  final List<Stage> stages;

  const Project({
    required this.id,
    required this.title,
    this.projectCode = '',
    this.description,
    this.stages = const [],
  });

  Project copyWith({
    String? title,
    String? description,
    String? projectCode,
    List<Stage>? stages,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectCode: projectCode ?? this.projectCode,
      stages: stages ?? this.stages,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'projectCode': projectCode,
    'stages': stages.map((s) => s.toJson()).toList(),
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    final titleVal = json['title'] as String? ?? '';
    final initials = titleVal.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join();
    final fallback = initials.isNotEmpty 
        ? (initials.length > 5 ? initials.substring(0, 4) : initials)
        : 'PRJ';
    return Project(
      id: json['id'],
      title: titleVal,
      description: json['description'],
      projectCode: json['projectCode'] ?? fallback,
      stages: (json['stages'] as List).map((s) => Stage.fromJson(s)).toList(),
    );
  }
}
