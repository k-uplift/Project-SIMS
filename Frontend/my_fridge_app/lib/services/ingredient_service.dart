import 'package:firebase_auth/firebase_auth.dart';

import '../models/ingredient.dart';
import '../models/user_profile.dart';
import '../repositories/fridge_repository.dart';
import '../repositories/ingredient_repository.dart';
import '../repositories/user_repository.dart';
import 'storage_service.dart';

/// UI 호환을 위한 wrapper. 내부적으로 IngredientRepository 호출.
///
/// 메인 냉장고:
/// - users/{uid}.primaryFridgeId 가 있고 fridgeIds에 포함되면 그걸 사용.
/// - 없으면 fridgeIds.first.
/// - 둘 다 없으면 새로 생성.
class IngredientService {
  IngredientService._();

  /// 캐시된 fridgeId. 메인 냉장고 변경 시 clearCache() 호출 필요.
  static String? _cachedFridgeId;

  /// 현재 사용자의 메인 냉장고 ID. 없으면 새로 생성.
  static Future<String> currentFridgeId() async {
    if (_cachedFridgeId != null) return _cachedFridgeId!;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');

    final profile = await UserRepository.instance.get(uid);
    final primary = profile?.effectivePrimaryFridgeId;
    if (primary != null) {
      _cachedFridgeId = primary;
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

  /// 메인 냉장고 변경 시 / 로그아웃 시 호출.
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

  /// 식재료 추가.
  ///
  /// [imageLocalPath]가 주어지면 Firebase Storage에 업로드 후 다운로드 URL을
  /// imageURL 필드에 저장한다. 업로드 실패 시에도 식재료 자체는 등록되고
  /// imageURL만 null이 된다 (UX 우선).
  ///
  /// 흐름: Firestore 문서 add → ingredientId 확보 → Storage 업로드 →
  ///       성공 시 imageURL update.
  static Future<Ingredient> addIngredient({
    required String name,
    required String category,
    String? emoji,
    int count = 1,
    required DateTime expireDate,
    String? imageLocalPath,
    String addedVia = IngredientSource.manual,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    final fridgeId = await currentFridgeId();

    // 1) 먼저 Firestore에 추가 (imageURL은 일단 null)
    var ingredient = await IngredientRepository.instance.add(
      fridgeId: fridgeId,
      name: name,
      category: category,
      emoji: emoji,
      count: count,
      expireDate: expireDate,
      imageURL: null,
      addedBy: uid,
      addedVia: addedVia,
    );

    // 2) 로컬 파일이 있으면 업로드
    if (imageLocalPath != null && imageLocalPath.isNotEmpty) {
      final url = await StorageService.uploadIngredientImage(
        fridgeId: fridgeId,
        ingredientId: ingredient.id,
        localFilePath: imageLocalPath,
      );

      // 3) 업로드 성공 시 Firestore에 URL 반영
      if (url != null) {
        await IngredientRepository.instance.update(
          fridgeId: fridgeId,
          ingredientId: ingredient.id,
          imageURL: url,
        );
        ingredient = ingredient.copyWith(imageURL: url);
      }
      // 실패 시: imageURL=null인 채로 그냥 둔다 (식재료는 이미 등록됨)
    }

    return ingredient;
  }

  /// 부분 업데이트. imageURL은 기존 값을 그대로 통과시키며,
  /// 이미지 자체를 새로 교체하는 흐름은 현재 화면에서 미지원.
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

  /// 식재료 삭제. Storage에 남은 이미지도 같이 정리.
  static Future<void> deleteIngredient(String id) async {
    final fridgeId = await currentFridgeId();
    await IngredientRepository.instance
        .delete(fridgeId: fridgeId, ingredientId: id);
    // Storage 정리는 best-effort (실패해도 무시).
    await StorageService.deleteIngredientImage(
      fridgeId: fridgeId,
      ingredientId: id,
    );
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