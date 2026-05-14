import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ingredient.dart';

class IngredientRepository {
  IngredientRepository._();
  static final instance = IngredientRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String fridgeId) {
    return _db.collection('fridges').doc(fridgeId).collection('ingredients');
  }

  /// 식재료 추가. 새 문서 ID를 자동 발급.
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

  /// OCR/이미지 인식 결과 일괄 저장 (batch write로 한번에).
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

  /// 유통기한 오름차순으로 전체 조회.
  Future<List<Ingredient>> list(String fridgeId) async {
    final query = await _collection(fridgeId)
        .orderBy('expireDate', descending: false)
        .get();
    return query.docs
        .map((doc) => Ingredient.fromFirestore(doc, fridgeId))
        .toList();
  }

  /// 실시간 스트림 (UI에서 StreamBuilder 사용).
  Stream<List<Ingredient>> watch(String fridgeId) {
    return _collection(fridgeId)
        .orderBy('expireDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Ingredient.fromFirestore(doc, fridgeId))
        .toList());
  }

  /// D-day가 [withinDays] 이하인 항목만 (홈/알림 화면용).
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

  /// 부분 업데이트 (null 아닌 필드만 갱신).
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

  /// 이름으로 부분 검색 (Firestore는 LIKE가 없어서 prefix 매칭으로 처리).
  Future<List<Ingredient>> searchByName({
    required String fridgeId,
    required String keyword,
  }) async {
    if (keyword.isEmpty) return [];
    // \uf8ff = Unicode private area 끝. prefix 검색 패턴.
    final query = await _collection(fridgeId)
        .where('name', isGreaterThanOrEqualTo: keyword)
        .where('name', isLessThanOrEqualTo: '$keyword\uf8ff')
        .get();
    return query.docs
        .map((doc) => Ingredient.fromFirestore(doc, fridgeId))
        .toList();
  }
}