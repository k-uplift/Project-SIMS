import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

class ChatRepository {
  ChatRepository._();
  static final instance = ChatRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessions(String uid) {
    return _db.collection('chats').doc(uid).collection('sessions');
  }

  CollectionReference<Map<String, dynamic>> _messages(
      String uid,
      String sessionId,
      ) {
    return _sessions(uid).doc(sessionId).collection('messages');
  }

  /// 새 세션 시작. 첫 메시지에서 자동으로 title 생성 (앞 20자).
  Future<ChatSession> createSession({
    required String uid,
    required String firstUserMessage,
    String? recipeId,
  }) async {
    final now = DateTime.now();
    final ref = _sessions(uid).doc();
    final title = firstUserMessage.length > 20
        ? '${firstUserMessage.substring(0, 20)}...'
        : firstUserMessage;
    final session = ChatSession(
      id: ref.id,
      title: title,
      recipeId: recipeId,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(session.toMap());
    return session;
  }

  Future<List<ChatSession>> listSessions(String uid) async {
    final query = await _sessions(uid)
        .orderBy('updatedAt', descending: true)
        .get();
    return query.docs.map(ChatSession.fromFirestore).toList();
  }

  Stream<List<ChatSession>> watchSessions(String uid) {
    return _sessions(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatSession.fromFirestore).toList());
  }

  /// 메시지 1건 추가 + 세션 updatedAt 갱신.
  Future<ChatMessage> addMessage({
    required String uid,
    required String sessionId,
    required String text,
    required String role,
  }) async {
    final now = DateTime.now();
    final ref = _messages(uid, sessionId).doc();
    final message = ChatMessage(
      id: ref.id,
      text: text,
      role: role,
      createdAt: now,
    );

    final batch = _db.batch();
    batch.set(ref, message.toMap());
    batch.update(_sessions(uid).doc(sessionId), {
      'updatedAt': Timestamp.fromDate(now),
    });
    await batch.commit();

    return message;
  }

  /// 시간순으로 메시지 조회.
  Future<List<ChatMessage>> listMessages({
    required String uid,
    required String sessionId,
  }) async {
    final query = await _messages(uid, sessionId)
        .orderBy('createdAt', descending: false)
        .get();
    return query.docs.map(ChatMessage.fromFirestore).toList();
  }

  Stream<List<ChatMessage>> watchMessages({
    required String uid,
    required String sessionId,
  }) {
    return _messages(uid, sessionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> deleteSession({
    required String uid,
    required String sessionId,
  }) async {
    // 메시지 서브컬렉션 먼저 비우기 (Firestore는 cascade delete 안 함)
    final msgs = await _messages(uid, sessionId).get();
    final batch = _db.batch();
    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessions(uid).doc(sessionId));
    await batch.commit();
  }
}