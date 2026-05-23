import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ingredient.dart';

class IngredientRepository {
  IngredientRepository._();
  static final instance = IngredientRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String fridgeId) {
    return _db.collection('fridges').doc(fridgeId).collection('ingredients');
  }

  /// 식재료 추가
  Future<Ingredient> add({
    required String fridgeId,
    required String name,
    required String category,
    String? emoji,
    int count = 1,
    required DateTime expireDate,
    String? imageURL,
    required String addedBy,
    String addedVia = IngredientSource.manual,
  }) async {
    final now = DateTime.now();
    final ref = _collection(fridgeId).doc();
    final ingredient = Ingredient(
      id: ref.id,
      fridgeId: fridgeId,
      name: name,
      category: category,
      emoji: emoji,
      count: count,
      expireDate: expireDate,
      imageURL: imageURL,
      addedBy: addedBy,
      addedVia: addedVia,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(ingredient.toMap());
    return ingredient;
  }

  /// 여러 식재료 저장
  Future<List<Ingredient>> addBatch({
    required String fridgeId,
    required List<Ingredient> items,
  }) async {
    final batch = _db.batch();
    final saved = <Ingredient>[];

    for (final item in items) {
      final ref = _collection(fridgeId).doc();
      final withId = Ingredient(
        id: ref.id,
        fridgeId: fridgeId,
        name: item.name,
        category: item.category,
        emoji: item.emoji,
        count: item.count,
        expireDate: item.expireDate,
        imageURL: item.imageURL,
        addedBy: item.addedBy,
        addedVia: item.addedVia,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );
      batch.set(ref, withId.toMap());
      saved.add(withId);
    }
    await batch.commit();
    return saved;
  }

  /// 식재료 목록
  Future<List<Ingredient>> list(String fridgeId) async {
    final query = await _collection(fridgeId)
        .orderBy('expireDate', descending: false)
        .get();
    return query.docs
        .map((doc) => Ingredient.fromFirestore(doc, fridgeId))
        .toList();
  }

  /// 실시간 목록
  Stream<List<Ingredient>> watch(String fridgeId) {
    return _collection(fridgeId)
        .orderBy('expireDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Ingredient.fromFirestore(doc, fridgeId))
        .toList());
  }

  /// 유통기한 임박 목록
  Stream<List<Ingredient>> watchExpiring(
      String fridgeId, {
        int withinDays = 7,
      }) {
    final cutoff = DateTime.now().add(Duration(days: withinDays));
    return _collection(fridgeId)
        .where('expireDate', isLessThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('expireDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Ingredient.fromFirestore(doc, fridgeId))
        .toList());
  }

  Future<Ingredient?> get({
    required String fridgeId,
    required String ingredientId,
  }) async {
    final snap = await _collection(fridgeId).doc(ingredientId).get();
    if (!snap.exists) return null;
    return Ingredient.fromFirestore(snap, fridgeId);
  }

  /// 식재료 수정
  Future<void> update({
    required String fridgeId,
    required String ingredientId,
    String? name,
    String? category,
    String? emoji,
    int? count,
    DateTime? expireDate,
    String? imageURL,
  }) async {
    final patch = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (name != null) patch['name'] = name;
    if (category != null) patch['category'] = category;
    if (emoji != null) patch['emoji'] = emoji;
    if (count != null) patch['count'] = count;
    if (expireDate != null) patch['expireDate'] = Timestamp.fromDate(expireDate);
    if (imageURL != null) patch['imageURL'] = imageURL;

    await _collection(fridgeId).doc(ingredientId).update(patch);
  }

  Future<void> delete({
    required String fridgeId,
    required String ingredientId,
  }) async {
    await _collection(fridgeId).doc(ingredientId).delete();
  }

  /// 이름으로 검색
  Future<List<Ingredient>> searchByName({
    required String fridgeId,
    required String keyword,
  }) async {
    if (keyword.isEmpty) return [];
    // prefix 검색용
    final query = await _collection(fridgeId)
        .where('name', isGreaterThanOrEqualTo: keyword)
        .where('name', isLessThanOrEqualTo: '$keyword\uf8ff')
        .get();
    return query.docs
        .map((doc) => Ingredient.fromFirestore(doc, fridgeId))
        .toList();
  }
}
