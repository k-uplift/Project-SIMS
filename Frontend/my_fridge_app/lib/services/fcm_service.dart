import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../repositories/fcm_token_repository.dart';

/// 백그라운드 메시지 핸들러는 top-level 함수여야 한다 (Dart isolate 격리 때문).
/// 여기선 별다른 처리 없이 시스템이 알림 트레이에 자동 표시하도록 둠.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드/종료 상태에서는 시스템이 notification payload를 자동으로
  // 트레이에 표시하므로 여기서 추가 작업 불필요.
  // 필요시 Firebase.initializeApp() 다시 호출 후 작업 가능.
  if (kDebugMode) {
    // ignore: avoid_print
    print('[FCM] background message: ${message.messageId}');
  }
}

class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// Android 알림 채널. AndroidManifest의 default_notification_channel_id와 일치.
  static const _channelId = 'fridge_expiring_channel';
  static const _channelName = '유통기한 알림';
  static const _channelDesc = '식재료 유통기한이 임박했을 때 알림을 보냅니다.';

  static bool _initialized = false;

  /// 알림 클릭 시 라우팅에 사용할 콜백. main.dart에서 설정.
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// 앱 시작 시 호출. main()의 Firebase.initializeApp() 직후.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1) 백그라운드 핸들러 등록 (반드시 top-level 함수)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2) 로컬 알림 플러그인 초기화 (포그라운드일 때 시스템 알림으로 표시)
    await _initLocalNotifications();

    // 3) iOS에서 포그라운드일 때도 시스템 알림 표시되도록
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4) 포그라운드 메시지: 직접 로컬 알림으로 띄움
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5) 백그라운드에서 알림 탭으로 앱을 열었을 때
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6) 종료 상태에서 알림 탭으로 앱을 시작했을 때
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleMessageOpenedApp(initial);
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // 로컬 알림 탭 시 payload 파싱해서 콜백 호출
        final payload = response.payload;
        if (payload != null && onNotificationTap != null) {
          onNotificationTap!({'payload': payload});
        }
      },
    );

    // Android 알림 채널 생성 (Android 8.0+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// 권한 요청 + 토큰 받아서 Firestore에 저장.
  /// 로그인 직후 / 앱 시작 시 currentUser != null일 때 호출.
  static Future<void> registerForUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 권한 요청 (iOS는 필수, Android 13+ 도 필요)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // 사용자가 거부해도 토큰 등록은 시도 (다음에 권한 주면 동작)
      if (kDebugMode) print('[FCM] 알림 권한 거부됨');
    }

    // 토큰 받기
    final token = await _messaging.getToken();
    if (token == null) {
      if (kDebugMode) print('[FCM] 토큰을 받지 못함');
      return;
    }

    final deviceId = await _resolveDeviceId();
    final platform =
    Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android;

    await FcmTokenRepository.instance.register(
      uid: uid,
      deviceId: deviceId,
      token: token,
      platform: platform,
    );

    // 토큰 갱신 리스너 (자동 갱신 시 호출됨)
    _messaging.onTokenRefresh.listen((newToken) async {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) return;
      await FcmTokenRepository.instance.register(
        uid: currentUid,
        deviceId: deviceId,
        token: newToken,
        platform: platform,
      );
    });

    if (kDebugMode) print('[FCM] 토큰 등록 완료: ${token.substring(0, 20)}...');
  }

  /// 로그아웃 시 호출. 토큰을 Firestore에서 제거.
  static Future<void> unregisterForUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final deviceId = await _resolveDeviceId();
    await FcmTokenRepository.instance.unregister(uid: uid, deviceId: deviceId);
  }

  /// 디바이스 ID. 정식으론 device_info_plus로 받지만, 여기선 FCM 토큰 자체를
  /// 임시 deviceId로 사용 (같은 디바이스면 토큰 갱신돼도 같은 문서를 덮어쓰도록
  /// installationId 기반이 더 정확하지만 의존성 추가 부담 줄이려 단순화).
  ///
  /// FirebaseMessaging의 getAPNSToken / Installations ID를 쓰는 방법도 있는데,
  /// 일단은 FCM 토큰의 앞 16자를 deviceId로 쓴다 — 같은 디바이스에선 일반적으로
  /// 동일 토큰 prefix가 유지됨.
  static Future<String> _resolveDeviceId() async {
    final token = await _messaging.getToken();
    if (token != null && token.length >= 16) {
      return token.substring(0, 16);
    }
    return 'unknown';
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null) return;

    // 포그라운드 상태에선 시스템이 자동 표시 안 하므로 직접 띄운다.
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) print('[FCM] 알림 탭으로 열림: ${message.messageId}');
    if (onNotificationTap != null) {
      onNotificationTap!(message.data);
    }
  }
}