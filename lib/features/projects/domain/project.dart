import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../stages/domain/stage.dart';

@immutable
class Project {
  final String id;
  final String title;
  final String description;
  final List<Stage> stages;

  const Project({
    required this.id,
    required this.title,
    required this.description,
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
}
