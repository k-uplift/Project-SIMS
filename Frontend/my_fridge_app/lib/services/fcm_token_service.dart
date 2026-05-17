import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/fcm_token_repository.dart';

/// FCM 토큰 서비스
class FcmTokenService {
  FcmTokenService._();

  /// 토큰 등록
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

  /// 토큰 삭제
  static Future<void> unregister(String deviceId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FcmTokenRepository.instance
        .unregister(uid: uid, deviceId: deviceId);
  }
}
