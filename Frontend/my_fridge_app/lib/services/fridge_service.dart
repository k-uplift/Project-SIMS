import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../repositories/fridge_repository.dart';
import '../repositories/user_repository.dart';
import 'ingredient_service.dart';
import 'user_profile_service.dart';

/// 공유 냉장고 참여 결과.
enum JoinFridgeResult {
  success,
  alreadyMember,
  codeNotFound,
  notLoggedIn,
}

/// 화면에 뿌리기 좋도록 냉장고 + 표시명(owner displayName 기반) 묶음.
/// "{닉네임}의 냉장고" 형식. owner 정보가 없으면 '알 수 없음의 냉장고'.
class FridgeView {
  final Fridge fridge;
  final String displayName;

  const FridgeView({required this.fridge, required this.displayName});

  String get id => fridge.id;
  int get memberCount => fridge.memberUids.length;
}

/// 화면에서 쓰는 냉장고 관련 wrapper.
///
/// 메인 냉장고:
/// - users/{uid}.primaryFridgeId 가 있고 fridgeIds에 포함되면 그걸 사용.
/// - 없으면 fridgeIds.first (기존 동작과 호환).
class FridgeService {
  FridgeService._();

  /// 냉장고 표시명. 항상 "{owner displayName}의 냉장고" 형식.
  /// Fridge.name 필드는 무시 (수동 이름이 있어도 일관성 위해 displayName 기준).
  static Future<String> displayNameFor(Fridge fridge) async {
    final ownerName = await UserProfileService.displayNameOf(fridge.ownerUid);
    return '$ownerName의 냉장고';
  }

  /// 현재 사용자의 메인 냉장고 ID. 없으면 null.
  static Future<String?> currentFridgeId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final profile = await UserRepository.instance.get(uid);
    return profile?.effectivePrimaryFridgeId;
  }

  /// 메인 냉장고 정보.
  static Future<Fridge?> currentFridge() async {
    final id = await currentFridgeId();
    if (id == null) return null;
    return FridgeRepository.instance.get(id);
  }

  /// 메인 냉장고의 표시명 (홈 화면 헤더용).
  static Future<String?> currentFridgeDisplayName() async {
    final fridge = await currentFridge();
    if (fridge == null) return null;
    return displayNameFor(fridge);
  }

  /// 사용자가 속한 모든 냉장고를 표시명까지 묶어서 반환.
  /// 화면 깜빡임 없이 한 번에 렌더링 가능.
  static Future<List<FridgeView>> myFridges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final profile = await UserRepository.instance.get(uid);
    if (profile == null || profile.fridgeIds.isEmpty) return [];

    final views = <FridgeView>[];
    for (final fid in profile.fridgeIds) {
      final f = await FridgeRepository.instance.get(fid);
      if (f == null) continue;
      final name = await displayNameFor(f);
      views.add(FridgeView(fridge: f, displayName: name));
    }
    return views;
  }

  /// 메인 냉장고 설정. 식재료 캐시도 같이 무효화.
  static Future<void> setPrimaryFridge(String fridgeId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UserRepository.instance.setPrimaryFridge(uid, fridgeId);
    IngredientService.clearCache();
  }

  /// 내 냉장고의 공유 코드. 구버전 데이터엔 없을 수 있어서 ensureInviteCode로
  /// 자동 발급까지 처리.
  static Future<String?> myInviteCode() async {
    final id = await currentFridgeId();
    if (id == null) return null;
    return FridgeRepository.instance.ensureInviteCode(id);
  }

  /// 공유 코드로 냉장고 참여.
  /// 이미 멤버면 alreadyMember 반환. 코드 자체가 없으면 codeNotFound.
  static Future<JoinFridgeResult> joinByCode(String code) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return JoinFridgeResult.notLoggedIn;

    final fridge = await FridgeRepository.instance.findByInviteCode(code);
    if (fridge == null) return JoinFridgeResult.codeNotFound;

    if (fridge.memberUids.contains(uid)) {
      return JoinFridgeResult.alreadyMember;
    }

    await FridgeRepository.instance.addMember(
      fridgeId: fridge.id,
      memberUid: uid,
    );
    return JoinFridgeResult.success;
  }
}