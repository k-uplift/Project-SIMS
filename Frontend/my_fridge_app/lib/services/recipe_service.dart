import 'package:firebase_auth/firebase_auth.dart';

import '../models/recipe.dart';
import '../repositories/recipe_history_repository.dart';

/// 레시피는 두 출처가 있다.
///   1) LLM이 실시간 생성 (FastAPI /recipes/recommend) — 향후 API 클라이언트 연결
///   2) 사용자가 본 적이 있는 레시피 (recipesHistory)
///
/// 현재는 LLM 호출이 아직 라우터에 연결 안 되어 있어서, 이 서비스는
/// "최근 본 레시피 이력" 위주로 동작한다. LLM 완성 시 fetchRecommendations()만
/// 교체하면 된다.
class RecipeService {
  RecipeService._();

  /// 최근 본 레시피 이력. 홈/레시피 탭에서 사용.
  static Future<List<Recipe>> getRecipes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final history = await RecipeHistoryRepository.instance.list(uid);
    return history.map((item) => item.recipe).toList();
  }

  static Stream<List<Recipe>> watchRecipes() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield [];
      return;
    }
    yield* RecipeHistoryRepository.instance
        .watch(uid)
        .map((items) => items.map((e) => e.recipe).toList());
  }

  /// 레시피 상세 화면 진입 시 호출 — "본 적 있음"으로 기록.
  static Future<void> recordView({
    required Recipe recipe,
    String source = RecipeSource.llm,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await RecipeHistoryRepository.instance.record(
      uid: uid,
      recipe: recipe,
      source: source,
    );
  }

  /// 이력에서 제목으로 검색.
  static Future<Recipe?> searchRecipe(String keyword) async {
    if (keyword.isEmpty) return null;
    final recipes = await getRecipes();
    for (final recipe in recipes) {
      if (recipe.title.contains(keyword)) return recipe;
    }
    return null;
  }

  static Future<Recipe?> getRecipeById(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final history = await RecipeHistoryRepository.instance.list(uid);
    for (final item in history) {
      if (item.recipe.id == id) return item.recipe;
    }
    return null;
  }

  /// LLM 추천 호출 (FastAPI 연결 후 구현). 현재는 빈 리스트.
  /// TODO: ApiClient 추가되면 여기서 POST /recipes/recommend 호출.
  static Future<List<Recipe>> fetchRecommendations() async {
    return [];
  }
}