import 'package:uuid/uuid.dart';

class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  Chat({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Chat copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool,
    );
  }
} 