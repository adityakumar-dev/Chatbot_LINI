import 'package:uuid/uuid.dart';

enum MessageType {
  text,
  image,
  voice,
}

enum MessageRole {
  user,
  assistant,
  system,
}

class Message {
  final String id;
  final String chatId;
  final String content;
  final MessageType type;
  final MessageRole role;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Message({
    String? id,
    required this.chatId,
    required this.content,
    this.type = MessageType.text,
    this.role = MessageRole.user,
    DateTime? timestamp,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Message copyWith({
    String? id,
    String? chatId,
    String? content,
    MessageType? type,
    MessageRole? role,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      type: type ?? this.type,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'content': content,
      'type': type.toString(),
      'role': role.toString(),
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      role: MessageRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
} 