import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
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
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data! ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}