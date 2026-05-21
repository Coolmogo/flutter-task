import '../../../users/model/user_model.dart';

class Comment {
  final String id;
  final String taskId;
  final String text;
  final User? author;
  final String? legacyAuthorName;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.taskId,
    required this.text,
    this.author,
    this.legacyAuthorName,
    required this.createdAt,
  });

  String get displayAuthorName => author?.name ?? legacyAuthorName ?? 'System';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'text': text,
      'author': author?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    final legacyAuthorName = json['authorName'] as String?;

    return Comment(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      text: json['text'] as String,
      author: authorJson is Map<String, dynamic>
          ? User.fromJson(authorJson)
          : null,
      legacyAuthorName: legacyAuthorName == 'System' ? null : legacyAuthorName,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
