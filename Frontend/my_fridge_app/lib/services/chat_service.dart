import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

/// 챗봇 세션과 메시지를 Firestore에 저장.
/// 실제 LLM 응답은 FastAPI /chat 엔드포인트가 담당 (향후 연결).
/// 이 서비스는 그 전후로 사용자 메시지/응답을 영속화하는 역할.
class ChatService {
  ChatService._();

  /// 새 세션 시작.
  static Future<ChatSession> startSession({
    required String firstUserMessage,
    String? recipeId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    return ChatRepository.instance.createSession(
      uid: uid,
      firstUserMessage: firstUserMessage,
      recipeId: recipeId,
    );
  }

  /// 사용자 메시지 저장.
  static Future<ChatMessage> sendUserMessage({
    required String sessionId,
    required String text,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    return ChatRepository.instance.addMessage(
      uid: uid,
      sessionId: sessionId,
      text: text,
      role: MessageRole.user,
    );
  }

  /// AI 응답 저장 (FastAPI 호출 결과).
  static Future<ChatMessage> saveAssistantReply({
    required String sessionId,
    required String text,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    return ChatRepository.instance.addMessage(
      uid: uid,
      sessionId: sessionId,
      text: text,
      role: MessageRole.assistant,
    );
  }

  /// 세션의 모든 메시지를 시간순으로 (UI에서 렌더링용).
  static Stream<List<ChatMessage>> watchMessages(String sessionId) async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield [];
      return;
    }
    yield* ChatRepository.instance
        .watchMessages(uid: uid, sessionId: sessionId);
  }

  /// 사용자가 가진 모든 채팅 세션 목록 (이력 화면용).
  static Stream<List<ChatSession>> watchSessions() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield [];
      return;
    }
    yield* ChatRepository.instance.watchSessions(uid);
  }

  static Future<void> deleteSession(String sessionId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await ChatRepository.instance
        .deleteSession(uid: uid, sessionId: sessionId);
  }

  /// 기존 UI 호환용 단발 호출 — 임시 더미 응답.
  /// FastAPI /chat 연결 시 ApiClient.postChat()으로 교체.
  @Deprecated('FastAPI /chat 연결 후 ApiClient.postChat()으로 교체 예정')
  static Future<ChatMessage> sendMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ChatMessage(
      id: 'tmp',
      text: 'AI 응답이 곧 연결됩니다. 메시지: $message',
      role: MessageRole.assistant,
      createdAt: DateTime.now(),
    );
  }
}