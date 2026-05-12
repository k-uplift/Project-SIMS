import 'package:firebase_auth/firebase_auth.dart';
import '../models/ingredient.dart';
import '../models/user_profile.dart';
import '../repositories/fridge_repository.dart';
import '../repositories/ingredient_repository.dart';
import '../repositories/user_repository.dart';

/// UI 호환을 위한 wrapper. 내부적으로 IngredientRepository 호출.
///
/// 사용자가 속한 첫 번째 fridgeId를 자동으로 조회하여 명령을 전달합니다.
class IngredientService {
  IngredientService._();

  /// 캐시된 fridgeId. 세션 동안 재사용하여 불필요한 DB 조회를 줄입니다.
  static String? _cachedFridgeId;

  /// 현재 사용자의 첫 번째 냉장고 ID 조회. 없으면 새로 생성.
  static Future<String> currentFridgeId() async {
    if (_cachedFridgeId != null) return _cachedFridgeId!;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');

    final profile = await UserRepository.instance.get(uid);
    if (profile != null && profile.fridgeIds.isNotEmpty) {
      _cachedFridgeId = profile.fridgeIds.first;
      return _cachedFridgeId!;
    }

    // 프로필이 없거나 fridgeIds가 비어있으면 기본 사용자 문서와 냉장고를 생성합니다.
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

  /// 로그아웃 시 캐시를 비웁니다.
  static void clearCache() {
    _cachedFridgeId = null;
  }

  /// 전체 식재료 목록 가져오기
  static Future<List<Ingredient>> getIngredients() async {
    final fridgeId = await currentFridgeId();
    return IngredientRepository.instance.list(fridgeId);
  }

  /// 실시간 식재료 스트림 (StreamBuilder용)
  static Stream<List<Ingredient>> watchIngredients() async* {
    final fridgeId = await currentFridgeId();
    yield* IngredientRepository.instance.watch(fridgeId);
  }

  /// 유통기한 임박 식재료 가져오기 (기본 7일 이내)
  static Future<List<Ingredient>> getExpiringIngredients({
    int withinDays = 7,
  }) async {
    final all = await getIngredients();
    return all.where((item) => item.dday <= withinDays).toList();
  }

  /// 유통기한 임박 식재료 스트림
  static Stream<List<Ingredient>> watchExpiringIngredients({
    int withinDays = 7,
  }) async* {
    final fridgeId = await currentFridgeId();
    yield* IngredientRepository.instance
        .watchExpiring(fridgeId, withinDays: withinDays);
  }

  /// 식재료 추가
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

  /// 식재료 정보 수정
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

  /// 식재료 삭제
  static Future<void> deleteIngredient(String id) async {
    final fridgeId = await currentFridgeId();
    await IngredientRepository.instance
        .delete(fridgeId: fridgeId, ingredientId: id);
  }

  /// 이름 기반 식재료 검색
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
