class Stage {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final List<String> statuses;

  const Stage({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.statuses = const ['To Do', 'In Progress', 'Done'],
  });

  Stage copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    List<String>? statuses,
  }) {
    return Stage(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      statuses: statuses ?? this.statuses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'statuses': statuses,
    };
  }

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      statuses:
          (json['statuses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['To Do', 'In Progress', 'Done'],
    );
  }
}
