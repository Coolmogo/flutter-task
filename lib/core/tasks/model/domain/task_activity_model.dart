import '../../../users/model/user_model.dart';

enum ActivityType { comment, history }

class ActivityLog {
  final String id;
  final String text;
  final User? author;
  final String? legacyAuthorName;
  final DateTime timestamp;
  final ActivityType type;

  const ActivityLog({
    required this.id,
    required this.text,
    this.author,
    this.legacyAuthorName,
    required this.timestamp,
    required this.type,
  });

  String get displayAuthorName => author?.name ?? legacyAuthorName ?? 'System';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    final legacyAuthorName = json['authorName'] as String?;

    return ActivityLog(
      id: json['id'] as String,
      text: json['text'] as String,
      author: authorJson is Map<String, dynamic>
          ? User.fromJson(authorJson)
          : null,
      legacyAuthorName: legacyAuthorName == 'System' ? null : legacyAuthorName,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ActivityType.values.byName(json['type'] as String? ?? 'comment'),
    );
  }
}
