import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../repositories/fridge_repository.dart';
import '../repositories/user_repository.dart';
import 'fcm_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 로그인된 사용자. 로그아웃 상태면 null.
  static User? get currentUser => _auth.currentUser;

  /// Firebase Auth의 상태 변화 스트림 (앱 진입 시 분기 처리에 사용).
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 사용자의 프로필 (Firestore users/{uid}).
  static Future<UserProfile?> currentProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return UserRepository.instance.get(uid);
  }

  /// 회원가입.
  static Future<String?> signUp({
    required String email,
    required String nickname,
    required String password,
    required String passwordConfirm,
  }) async {
    if (password != passwordConfirm) {
      return '입력하신 비밀번호 값이 다릅니다.';
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return '회원가입에 실패했습니다.';

      await UserRepository.instance.createOrUpdate(
        uid: user.uid,
        email: email,
        displayName: nickname,
      );

      await FridgeRepository.instance.create(
        ownerUid: user.uid,
        name: '$nickname의 냉장고',
      );

      // 회원가입 성공 직후도 토큰 등록 (가입하자마자 자동 로그인 상태)
      // fire-and-forget — 실패해도 회원가입 자체엔 영향 없음
      FcmService.registerForUser();

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return '이미 존재하는 이메일입니다.';
        case 'invalid-email':
          return '잘못된 이메일 형식입니다.';
        case 'weak-password':
          return '비밀번호는 6자 이상이어야 합니다.';
        default:
          return '회원가입 중 오류가 발생했습니다: ${e.code}';
      }
    } catch (e) {
      return '회원가입 중 오류가 발생했습니다.';
    }
  }

  /// 로그인. 성공 시 FCM 토큰 등록까지.
  static Future<bool> login({
    required String email,
    required String password,
    bool rememberLogin = true,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 로그인 직후 토큰 등록 (fire-and-forget)
      FcmService.registerForUser();
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  /// 앱 시작 시 호출.
  static Future<bool> checkSavedLogin() async {
    return _auth.currentUser != null;
  }

  /// 로그아웃. 토큰 해제 후 signOut.
  static Future<void> logout() async {
    // 토큰 먼저 해제 (signOut하면 uid가 사라져서 못 함)
    try {
      await FcmService.unregisterForUser();
    } catch (_) {
      // 토큰 해제 실패해도 로그아웃은 진행
    }
    await _auth.signOut();
  }
}
