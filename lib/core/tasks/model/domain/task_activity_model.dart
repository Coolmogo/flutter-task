import '../../../users/model/user_model.dart';

enum ActivityType { comment, history }

enum ActivityAction { commented, updated, removed, assigned, moved }

class ActivityLog {
  final String id;
  final String? text;
  final User? author;
  final String? legacyAuthorName;
  final DateTime timestamp;
  final ActivityType type;
  final ActivityAction action;
  final String? field;
  final Object? oldValue;
  final Object? newValue;

  const ActivityLog({
    required this.id,
    this.text,
    this.author,
    this.legacyAuthorName,
    required this.timestamp,
    required this.type,
    required this.action,
    this.field,
    this.oldValue,
    this.newValue,
  });

  String get displayAuthorName => author?.name ?? legacyAuthorName ?? 'System';

  String get displayText {
    if (text != null && text!.isNotEmpty) return text!;

    if (type == ActivityType.comment) return '';

    final label = _fieldLabel(field);
    final oldDisplay = _displayValue(oldValue);
    final newDisplay = _displayValue(newValue);

    switch (action) {
      case ActivityAction.assigned:
        if (oldValue == null && newValue != null) {
          return 'Assigned task to $newDisplay';
        }
        if (newValue == null) return 'Removed assignee (Unassigned)';
        return 'Changed assignee from $oldDisplay to $newDisplay';
      case ActivityAction.removed:
        return 'Removed $label';
      case ActivityAction.moved:
        return 'Moved $label from $oldDisplay to $newDisplay';
      case ActivityAction.updated:
        return 'Changed $label from $oldDisplay to $newDisplay';
      case ActivityAction.commented:
        return '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'action': action.name,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    final legacyAuthorName = json['authorName'] as String?;
    final type = ActivityType.values.byName(
      json['type'] as String? ?? 'comment',
    );
    final actionName = json['action'] as String?;

    return ActivityLog(
      id: json['id'] as String,
      text: json['text'] as String?,
      author: authorJson is Map<String, dynamic>
          ? User.fromJson(authorJson)
          : null,
      legacyAuthorName: legacyAuthorName == 'System' ? null : legacyAuthorName,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: type,
      action: _parseAction(actionName, type),
      field: json['field'] as String?,
      oldValue: json['oldValue'],
      newValue: json['newValue'],
    );
  }

  factory ActivityLog.fromBackendActivityJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    final authorId = json['author_id'];
    final authorType = json['author_type'] as String?;
    final legacyAuthorName = json['legacy_author_name'] as String?;
    final typeName = (json['type'] as String? ?? 'history').toLowerCase();
    final actionName = json['action'] as String?;

    return ActivityLog(
      id: json['id'].toString(),
      text: json['text'] as String?,
      author: authorJson is Map<String, dynamic>
          ? User.fromJson(authorJson)
          : _backendUser(
              authorId: authorId,
              authorType: authorType,
              legacyAuthorName: legacyAuthorName,
            ),
      legacyAuthorName: legacyAuthorName == 'System' ? null : legacyAuthorName,
      timestamp: DateTime.parse(
        (json['created_at'] ?? json['timestamp']) as String,
      ),
      type: typeName == 'comment' ? ActivityType.comment : ActivityType.history,
      action: _parseBackendAction(actionName, typeName),
      field: _normalizeBackendField(json['field'] as String?),
      oldValue: json['old_value'] ?? json['oldValue'],
      newValue: json['new_value'] ?? json['newValue'],
    );
  }

  factory ActivityLog.fromBackendCommentJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    final authorId = json['author_id'];
    final authorType = json['author_type'] as String?;
    final legacyAuthorName = json['legacy_author_name'] as String?;
    final content = json['content'] as String?;

    return ActivityLog(
      id: 'comment-${json['id']}',
      text: content ?? json['text'] as String? ?? '',
      author: authorJson is Map<String, dynamic>
          ? User.fromJson(authorJson)
          : _backendUser(
              authorId: authorId,
              authorType: authorType,
              legacyAuthorName: legacyAuthorName,
            ),
      legacyAuthorName: legacyAuthorName == 'System' ? null : legacyAuthorName,
      timestamp: DateTime.parse(
        (json['created_at'] ?? json['timestamp']) as String,
      ),
      type: ActivityType.comment,
      action: ActivityAction.commented,
    );
  }

  static User? _backendUser({
    required Object? authorId,
    required String? authorType,
    required String? legacyAuthorName,
  }) {
    if (authorId == null) {
      return null;
    }

    final normalizedId = authorId.toString();
    final normalizedName = legacyAuthorName?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      return User(id: normalizedId, name: normalizedName);
    }

    if (normalizedId == 'user:spark' || authorType == 'mogo') {
      return const User(id: 'user:spark', name: 'Spark');
    }
    if (normalizedId == 'current_user') {
      return const User(id: 'current_user', name: 'You');
    }

    return User(id: normalizedId, name: 'User #$normalizedId');
  }

  static ActivityAction _parseAction(String? actionName, ActivityType type) {
    if (actionName != null) {
      for (final action in ActivityAction.values) {
        if (action.name == actionName) return action;
      }
    }
    return _legacyActionFor(type);
  }

  static ActivityAction _legacyActionFor(ActivityType type) {
    return type == ActivityType.comment
        ? ActivityAction.commented
        : ActivityAction.updated;
  }

  static ActivityAction _parseBackendAction(
    String? actionName,
    String typeName,
  ) {
    final normalized = actionName?.toLowerCase();
    switch (normalized) {
      case 'commented':
        return ActivityAction.commented;
      case 'updated':
        return ActivityAction.updated;
      case 'removed':
        return ActivityAction.removed;
      case 'assigned':
        return ActivityAction.assigned;
      case 'moved':
        return ActivityAction.moved;
      default:
        return typeName == 'comment'
            ? ActivityAction.commented
            : ActivityAction.updated;
    }
  }

  static String? _normalizeBackendField(String? field) {
    switch (field) {
      case 'due':
      case 'due_date':
        return 'dueDate';
      case 'assignee_id':
        return 'assignee';
      case 'stage_id':
        return 'stageId';
      default:
        return field;
    }
  }

  static String _fieldLabel(String? field) {
    switch (field) {
      case 'title':
        return 'title';
      case 'description':
        return 'description';
      case 'dueDate':
        return 'due date';
      case 'assignee':
        return 'assignee';
      case 'status':
        return 'status';
      case 'stageId':
        return 'stage';
      default:
        return field ?? 'task';
    }
  }

  static String _displayValue(Object? value) {
    if (value == null) return 'none';
    if (value is String) {
      final parsedDate = DateTime.tryParse(value);
      if (parsedDate != null) return _formatDate(parsedDate);
      return value;
    }
    if (value is Map) {
      final name = value['name'];
      final title = value['title'];
      final id = value['id'];
      return (name ?? title ?? id ?? value).toString();
    }
    return value.toString();
  }

  static String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
