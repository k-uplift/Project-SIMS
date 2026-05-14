import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notification_screen.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';

/// 알림 탭으로 라우팅하기 위한 글로벌 네비게이터 키.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. FCM 초기화 (포그라운드/백그라운드 리스너 등록까지)
  await FcmService.initialize();

  // 4. 알림 탭 시 알림 화면으로 이동하도록 콜백 설정
  FcmService.onNotificationTap = (data) {
    // 데이터에 type=expiring 같은 게 있으면 알림 화면으로
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  };

  // 5. 이미 로그인된 상태면 FCM 토큰 등록 시도
  if (AuthService.currentUser != null) {
    // await 안 함: 앱 시작이 막히지 않도록 fire-and-forget
    FcmService.registerForUser();
  }

  runApp(const MyFridgeApp());
}

class MyFridgeApp extends StatelessWidget {
  const MyFridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '냉장고를 부탁해',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAF7),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: AuthService.checkSavedLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data == true ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
