import 'package:cloud_firestore/cloud_firestore.dart';

class MessageRole {
  static const user = 'user';
  static const assistant = 'assistant';
  static const system = 'system';
}

class ChatMessage {
  final String id;
  final String text;
  final String role;          // user | assistant | system
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    required this.createdAt,
  });

  /// 기존 UI 호환을 위한 편의 getter
  bool get isUser => role == MessageRole.user;

  factory ChatMessage.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      text: data['text'] as String? ?? '',
      role: data['role'] as String? ?? MessageRole.assistant,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// chats/{uid}/sessions/{sessionId}
class ChatSession {
  final String id;
  final String title;
  final String? recipeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    required this.id,
    required this.title,
    this.recipeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return ChatSession(
      id: doc.id,
      title: data['title'] as String? ?? '',
      recipeId: data['recipeId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      if (recipeId != null) 'recipeId': recipeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}