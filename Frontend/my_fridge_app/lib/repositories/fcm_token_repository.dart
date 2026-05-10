import 'package:cloud_firestore/cloud_firestore.dart';

class DevicePlatform {
  static const android = 'android';
  static const ios = 'ios';
}

class FcmTokenRepository {
  FcmTokenRepository._();
  static final instance = FcmTokenRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _devices(String uid) {
    return _db.collection('fcmTokens').doc(uid).collection('devices');
  }

  /// 앱 시작 시 FCM 토큰 받으면 호출. deviceId가 같으면 토큰만 갱신.
  Future<void> register({
    required String uid,
    required String deviceId,
    required String token,
    String platform = DevicePlatform.android,
  }) async {
    await _devices(uid).doc(deviceId).set({
      'token': token,
      'platform': platform,
      'lastSeenAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  /// 로그아웃 시 호출.
  Future<void> unregister({
    required String uid,
    required String deviceId,
  }) async {
    await _devices(uid).doc(deviceId).delete();
  }

  /// Cloud Functions가 FCM 발송할 때 사용 (앱에서는 보통 안 씀).
  Future<List<String>> tokensFor(String uid) async {
    final snap = await _devices(uid).get();
    return snap.docs
        .map((doc) => doc.data()['token'] as String?)
        .whereType<String>()
        .toList();
  }
}