import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

class RecipeHistoryRepository {
  RecipeHistoryRepository._();
  static final instance = RecipeHistoryRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('recipesHistory').doc(uid).collection('items');
  }

  /// 레시피를 본/저장한 순간 호출. 같은 recipeId면 viewedAt만 갱신.
  Future<void> record({
    required String uid,
    required Recipe recipe,
    String source = RecipeSource.llm,
  }) async {
    final now = DateTime.now();
    final ref = _collection(uid).doc(recipe.id);
    final item = RecipeHistoryItem(
      recipe: recipe,
      source: source,
      viewedAt: now,
    );
    await ref.set(item.toMap(), SetOptions(merge: true));
  }

  /// 최근 본 순서대로 (limit 기본 50개).
  Future<List<RecipeHistoryItem>> list(
      String uid, {
        int limit = 50,
      }) async {
    final query = await _collection(uid)
        .orderBy('viewedAt', descending: true)
        .limit(limit)
        .get();
    return query.docs.map(RecipeHistoryItem.fromFirestore).toList();
  }

  Stream<List<RecipeHistoryItem>> watch(
      String uid, {
        int limit = 50,
      }) {
    return _collection(uid)
        .orderBy('viewedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(RecipeHistoryItem.fromFirestore).toList());
  }

  Future<void> remove({
    required String uid,
    required String recipeId,
  }) async {
    await _collection(uid).doc(recipeId).delete();
  }
}