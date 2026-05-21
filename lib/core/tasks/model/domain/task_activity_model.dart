enum ActivityType { comment, history }

class ActivityLog {
  final String id;
  final String text;
  final String authorName;
  final DateTime timestamp;
  final ActivityType type;

  const ActivityLog({
    required this.id,
    required this.text,
    required this.authorName,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'authorName': authorName,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      text: json['text'] as String,
      authorName: json['authorName'] as String? ?? 'System',
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ActivityType.values.byName(json['type'] as String? ?? 'comment'),
    );
  }
}
