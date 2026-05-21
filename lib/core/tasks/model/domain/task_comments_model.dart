class Comment {
  final String id;
  final String taskId;
  final String text;
  final String authorName;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.taskId,
    required this.text,
    required this.authorName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'text': text,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
    };
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
