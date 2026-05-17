import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../repositories/fridge_repository.dart';
import '../repositories/user_repository.dart';
import 'ingredient_service.dart';
import 'user_profile_service.dart';

/// 냉장고 참여 결과
enum JoinFridgeResult {
  success,
  alreadyMember,
  codeNotFound,
  notLoggedIn,
}

/// 냉장고 화면용 데이터
class FridgeView {
  final Fridge fridge;
  final String displayName;

  const FridgeView({required this.fridge, required this.displayName});

  String get id => fridge.id;
  int get memberCount => fridge.memberUids.length;
}

/// 냉장고 처리 서비스
class FridgeService {
  FridgeService._();

  /// 냉장고 이름 표시
  static Future<String> displayNameFor(Fridge fridge) async {
    final ownerName = await UserProfileService.displayNameOf(fridge.ownerUid);
    return '$ownerName의 냉장고';
  }

  /// 현재 냉장고 ID
  static Future<String?> currentFridgeId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final profile = await UserRepository.instance.get(uid);
    return profile?.effectivePrimaryFridgeId;
  }

  /// 현재 냉장고 정보
  static Future<Fridge?> currentFridge() async {
    final id = await currentFridgeId();
    if (id == null) return null;
    return FridgeRepository.instance.get(id);
  }

  /// 현재 냉장고 이름
  static Future<String?> currentFridgeDisplayName() async {
    final fridge = await currentFridge();
    if (fridge == null) return null;
    return displayNameFor(fridge);
  }

  /// 내 냉장고 목록
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

  /// 메인 냉장고 변경
  static Future<void> setPrimaryFridge(String fridgeId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await UserRepository.instance.setPrimaryFridge(uid, fridgeId);
    IngredientService.clearCache();
  }

  /// 내 공유 코드
  static Future<String?> myInviteCode() async {
    final id = await currentFridgeId();
    if (id == null) return null;
    return FridgeRepository.instance.ensureInviteCode(id);
  }

  /// 공유 코드로 참여
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
