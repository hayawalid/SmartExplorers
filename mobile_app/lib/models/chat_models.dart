/// Chat models matching the backend API schemas

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;

  ChatMessage({required this.role, required this.content, this.timestamp});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}

class ChatRequest {
  final String message;
  final String? conversationId;
  final Map<String, dynamic>? userContext;

  ChatRequest({required this.message, this.conversationId, this.userContext});

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (conversationId != null) 'conversation_id': conversationId,
      if (userContext != null) 'user_context': userContext,
    };
  }
}

class ChatResponse {
  final String message;
  final String conversationId;
  final List<String>? suggestions;
  final DateTime timestamp;

  ChatResponse({
    required this.message,
    required this.conversationId,
    this.suggestions,
    required this.timestamp,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      message: json['message'] as String,
      conversationId: json['conversation_id'] as String,
      suggestions:
          json['suggestions'] != null
              ? List<String>.from(json['suggestions'] as List)
              : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ConversationHistory {
  final String conversationId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationHistory({
    required this.conversationId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationHistory.fromJson(Map<String, dynamic> json) {
    return ConversationHistory(
      conversationId: json['conversation_id'] as String,
      messages:
          (json['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
              .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
