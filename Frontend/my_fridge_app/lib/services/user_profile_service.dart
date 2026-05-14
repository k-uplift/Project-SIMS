import '../models/user_profile.dart';
import '../repositories/user_repository.dart';

/// uid -> displayName 메모리 캐시.
/// 냉장고 이름을 owner displayName으로 표시할 때 자주 조회되므로 캐싱.
/// 같은 세션 안에서는 한 번만 Firestore를 읽음.
class UserProfileService {
  UserProfileService._();

  static final Map<String, UserProfile> _cache = {};
  static final Map<String, Future<UserProfile?>> _inflight = {};

  /// 캐시 우선 조회. 없으면 Firestore 읽고 캐시에 저장.
  /// 동시에 같은 uid를 요청해도 한 번만 읽도록 inflight 관리.
  static Future<UserProfile?> get(String uid) async {
    final cached = _cache[uid];
    if (cached != null) return cached;

    final pending = _inflight[uid];
    if (pending != null) return pending;

    final future = UserRepository.instance.get(uid).then((profile) {
      if (profile != null) _cache[uid] = profile;
      _inflight.remove(uid);
      return profile;
    }).catchError((e) {
      _inflight.remove(uid);
      return null as UserProfile?;
    });
    _inflight[uid] = future;
    return future;
  }

  /// uid -> displayName. 없으면 '알 수 없음'.
  static Future<String> displayNameOf(String uid) async {
    final profile = await get(uid);
    final name = profile?.displayName;
    if (name == null || name.isEmpty) return '알 수 없음';
    return name;
  }

  /// 본인 또는 다른 사용자의 정보를 갱신했을 때 호출.
  static void invalidate(String uid) {
    _cache.remove(uid);
  }

  static void clearAll() {
    _cache.clear();
    _inflight.clear();
  }
}