import 'package:firebase_auth/firebase_auth.dart';

import '../models/ingredient.dart';
import '../models/user_profile.dart';
import '../repositories/fridge_repository.dart';
import '../repositories/ingredient_repository.dart';
import '../repositories/user_repository.dart';

/// UI 호환을 위한 wrapper. 내부적으로 IngredientRepository 호출.
///
/// 기존 코드는 userId 한 명 기준으로 동작했지만, 실제 데이터 모델은 fridgeId
/// 단위로 동작한다. 사용자가 속한 첫 번째 fridgeId를 자동으로 사용.
class IngredientService {
  IngredientService._();

  /// 캐시된 fridgeId. 한 번 조회하면 세션 동안 재사용.
  static String? _cachedFridgeId;

  /// 현재 사용자의 첫 번째 냉장고 ID. 없으면 새로 생성.
  static Future<String> currentFridgeId() async {
    if (_cachedFridgeId != null) return _cachedFridgeId!;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');

    final profile = await UserRepository.instance.get(uid);
    if (profile != null && profile.fridgeIds.isNotEmpty) {
      _cachedFridgeId = profile.fridgeIds.first;
      return _cachedFridgeId!;
    }

    // 프로필이 없거나 fridgeIds가 비어있으면 새로 만든다 (구버전 사용자 대비).
    if (profile == null) {
      await UserRepository.instance.createOrUpdate(
        uid: uid,
        email: FirebaseAuth.instance.currentUser?.email ?? '',
      );
    }
    final fridge = await FridgeRepository.instance.create(ownerUid: uid);
    _cachedFridgeId = fridge.id;
    return _cachedFridgeId!;
  }

  /// 로그아웃 시 호출 (다음 로그인 사용자가 다른 사람일 수 있음).
  static void clearCache() {
    _cachedFridgeId = null;
  }

  static Future<List<Ingredient>> getIngredients() async {
    final fridgeId = await currentFridgeId();
    return IngredientRepository.instance.list(fridgeId);
  }

  /// 실시간 동기화가 필요한 화면에서 사용 (StreamBuilder).
  static Stream<List<Ingredient>> watchIngredients() async* {
    final fridgeId = await currentFridgeId();
    yield* IngredientRepository.instance.watch(fridgeId);
  }

  /// 유통기한 7일 이내.
  static Future<List<Ingredient>> getExpiringIngredients({
    int withinDays = 7,
  }) async {
    final all = await getIngredients();
    return all.where((item) => item.dday <= withinDays).toList();
  }

  static Stream<List<Ingredient>> watchExpiringIngredients({
    int withinDays = 7,
  }) async* {
    final fridgeId = await currentFridgeId();
    yield* IngredientRepository.instance
        .watchExpiring(fridgeId, withinDays: withinDays);
  }

  static Future<Ingredient> addIngredient({
    required String name,
    required String category,
    String? emoji,
    int count = 1,
    required DateTime expireDate,
    String? imageURL,
    String addedVia = IngredientSource.manual,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    final fridgeId = await currentFridgeId();

    return IngredientRepository.instance.add(
      fridgeId: fridgeId,
      name: name,
      category: category,
      emoji: emoji,
      count: count,
      expireDate: expireDate,
      imageURL: imageURL,
      addedBy: uid,
      addedVia: addedVia,
    );
  }

  static Future<void> updateIngredient(Ingredient ingredient) async {
    await IngredientRepository.instance.update(
      fridgeId: ingredient.fridgeId,
      ingredientId: ingredient.id,
      name: ingredient.name,
      category: ingredient.category,
      emoji: ingredient.emoji,
      count: ingredient.count,
      expireDate: ingredient.expireDate,
      imageURL: ingredient.imageURL,
    );
  }

  static Future<void> deleteIngredient(String id) async {
    final fridgeId = await currentFridgeId();
    await IngredientRepository.instance
        .delete(fridgeId: fridgeId, ingredientId: id);
  }

  /// 부분 일치 검색 (홈 화면 검색바용).
  static Future<Ingredient?> searchIngredient(String keyword) async {
    if (keyword.isEmpty) return null;
    final fridgeId = await currentFridgeId();
    final results = await IngredientRepository.instance.searchByName(
      fridgeId: fridgeId,
      keyword: keyword,
    );
    return results.isEmpty ? null : results.first;
  }
}