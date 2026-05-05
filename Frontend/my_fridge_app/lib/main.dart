import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 추가
import 'firebase_options.dart'; // FlutterFire CLI로 생성된 파일
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // 1. Flutter 바인딩 초기화 확인
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 파이어베이스 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyFridgeApp());
}

class MyFridgeApp extends StatelessWidget {
  const MyFridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '냉장고를 부탁해',
      debugShowCheckedModeBanner: false,
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