import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/fcm_token_repository.dart';

/// FCM 토큰을 Firestore에 등록/해제.
/// 실제 FirebaseMessaging 호출은 메인 앱 부트스트랩 단에서 (firebase_messaging
/// 패키지 추가 후) 토큰을 받아 이 서비스에 전달하는 흐름으로 사용.
class FcmTokenService {
  FcmTokenService._();

  /// 앱 시작 시 호출. (deviceId, token, platform)을 전달.
  static Future<void> register({
    required String deviceId,
    required String token,
    String platform = DevicePlatform.android,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FcmTokenRepository.instance.register(
      uid: uid,
      deviceId: deviceId,
      token: token,
      platform: platform,
    );
  }

  /// 로그아웃 시 호출.
  static Future<void> unregister(String deviceId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FcmTokenRepository.instance
        .unregister(uid: uid, deviceId: deviceId);
  }
}