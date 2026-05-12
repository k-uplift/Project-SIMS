import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../repositories/fridge_repository.dart';
import '../repositories/user_repository.dart';

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
  /// 성공 시 null, 실패 시 사람이 읽을 수 있는 에러 메시지를 반환.
  /// 가입 직후 users/{uid} 문서를 만들고, 기본 냉장고를 1개 생성한다.
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

      // Firestore 사용자 프로필 생성
      await UserRepository.instance.createOrUpdate(
        uid: user.uid,
        email: email,
        displayName: nickname,
      );

      // 기본 냉장고 1개 생성 (멤버=본인)
      await FridgeRepository.instance.create(
        ownerUid: user.uid,
        name: '내 냉장고',
      );

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

  /// 로그인. 기존 인터페이스(rememberLogin 포함) 유지.
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
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  /// 앱 시작 시 호출. Firebase Auth가 토큰을 자동 복구하므로
  /// currentUser != null 이면 자동 로그인된 상태.
  static Future<bool> checkSavedLogin() async {
    return _auth.currentUser != null;
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
