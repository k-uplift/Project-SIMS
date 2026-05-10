import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String id;
  final String email;
  final String nickname;
  final String password;

  const AppUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.password,
  });
}

class AuthService {
  static final List<AppUser> _users = [
    const AppUser(
      id: 'user_1',
      email: 'test@test.com',
      nickname: '테스트',
      password: '1234',
    ),
  ];

  static AppUser? currentUser;

  static Future<String?> signUp({
    required String email,
    required String nickname,
    required String password,
    required String passwordConfirm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final exists = _users.any((user) => user.email == email);

    if (exists) {
      return '이미 존재하는 아이디입니다.';
    }

    if (password != passwordConfirm) {
      return '입력하신 비밀번호 값이 다릅니다.';
    }

    final user = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      nickname: nickname,
      password: password,
    );

    _users.add(user);

    return null;
  }

  static Future<bool> login({
    required String email,
    required String password,
    required bool rememberLogin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final user = _users.firstWhere(
            (user) => user.email == email && user.password == password,
      );

      currentUser = user;

      final prefs = await SharedPreferences.getInstance();

      if (rememberLogin) {
        await prefs.setBool('rememberLogin', true);
        await prefs.setString('savedEmail', email);
        await prefs.setString('savedPassword', password);
      } else {
        await prefs.clear();
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final rememberLogin = prefs.getBool('rememberLogin') ?? false;
    final email = prefs.getString('savedEmail');
    final password = prefs.getString('savedPassword');

    if (!rememberLogin || email == null || password == null) {
      return false;
    }

    return login(
      email: email,
      password: password,
      rememberLogin: true,
    );
  }

  static Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
