class ChatMessageModel {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class ChatSessionModel {
  final String id;
  final String userId;
  final String? documentId;
  final String title;
  final DateTime createdAt;

  const ChatSessionModel({
    required this.id,
    required this.userId,
    this.documentId,
    required this.title,
    required this.createdAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      documentId: json['document_id'] as String?,
      title: json['title'] as String? ?? 'New Chat',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
