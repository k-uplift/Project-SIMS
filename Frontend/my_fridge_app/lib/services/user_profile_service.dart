import '../models/user_profile.dart';
import '../repositories/user_repository.dart';

/// 사용자 정보 캐시
class UserProfileService {
  UserProfileService._();

  static final Map<String, UserProfile> _cache = {};
  static final Map<String, Future<UserProfile?>> _inflight = {};

  /// 사용자 정보 가져오기
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

  /// 사용자 이름 가져오기
  static Future<String> displayNameOf(String uid) async {
    final profile = await get(uid);
    final name = profile?.displayName;
    if (name == null || name.isEmpty) return '알 수 없음';
    return name;
  }

  /// 캐시 삭제
  static void invalidate(String uid) {
    _cache.remove(uid);
  }

  static void clearAll() {
    _cache.clear();
    _inflight.clear();
  }
}
