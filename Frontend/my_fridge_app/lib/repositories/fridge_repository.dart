import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import 'user_repository.dart';

class FridgeRepository {
  FridgeRepository._();
  static final instance = FridgeRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _fridges =>
      _db.collection('fridges');

  /// 냉장고 새로 생성. owner를 memberUids에도 포함시키고 user.fridgeIds에 등록.
  Future<Fridge> create({
    required String ownerUid,
    String name = '내 냉장고',
  }) async {
    final now = DateTime.now();
    final ref = _fridges.doc();
    final fridge = Fridge(
      id: ref.id,
      name: name,
      ownerUid: ownerUid,
      memberUids: [ownerUid],
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(fridge.toMap());
    await UserRepository.instance.addFridgeId(ownerUid, ref.id);
    return fridge;
  }

  Future<Fridge?> get(String fridgeId) async {
    final snapshot = await _fridges.doc(fridgeId).get();
    if (!snapshot.exists) return null;
    return Fridge.fromFirestore(snapshot);
  }

  Stream<Fridge?> watch(String fridgeId) {
    return _fridges.doc(fridgeId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Fridge.fromFirestore(snapshot);
    });
  }

  /// 동거인 추가: fridge.memberUids + user.fridgeIds 양쪽 갱신.
  Future<void> addMember({
    required String fridgeId,
    required String memberUid,
  }) async {
    await _fridges.doc(fridgeId).update({
      'memberUids': FieldValue.arrayUnion([memberUid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await UserRepository.instance.addFridgeId(memberUid, fridgeId);
  }

  Future<void> removeMember({
    required String fridgeId,
    required String memberUid,
  }) async {
    await _fridges.doc(fridgeId).update({
      'memberUids': FieldValue.arrayRemove([memberUid]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await UserRepository.instance.removeFridgeId(memberUid, fridgeId);
  }

  Future<void> rename(String fridgeId, String newName) async {
    await _fridges.doc(fridgeId).update({
      'name': newName,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}