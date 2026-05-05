import '../models/chat_message.dart';

class ChatService {
  static Future<ChatMessage> sendMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const ChatMessage(
      text: '보유한 식재료를 기준으로 계란 볶음밥과 크림 파스타를 추천합니다.',
      isUser: false,
    );
  }
}