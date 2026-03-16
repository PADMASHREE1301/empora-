// lib/models/chat_message_model.dart

class ChatMessage {
  final String role;     // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role:      json['role'] as String,
      content:   json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'role':      role,
    'content':   content,
    'timestamp': timestamp.toIso8601String(),
  };
}