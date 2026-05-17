import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import 'user_repository.dart';

class FridgeRepository {
  FridgeRepository._();
  static final instance = FridgeRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _fridges =>
      _db.collection('fridges');

  /// 공유 코드 문자
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// 공유 코드 만들기
  Future<String> _generateUniqueInviteCode() async {
    final rng = Random.secure();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = List.generate(
        6,
            (_) => _codeAlphabet[rng.nextInt(_codeAlphabet.length)],
      ).join();

      final existing = await _fridges
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return code;
    }
    // 혹시 겹치면 7자리로 생성
    final rng2 = Random.secure();
    return List.generate(
      7,
          (_) => _codeAlphabet[rng2.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// 냉장고 생성
  Future<Fridge> create({
    required String ownerUid,
    String name = '내 냉장고',
  }) async {
    final now = DateTime.now();
    final ref = _fridges.doc();
    final inviteCode = await _generateUniqueInviteCode();
    final fridge = Fridge(
      id: ref.id,
      name: name,
      ownerUid: ownerUid,
      memberUids: [ownerUid],
      inviteCode: inviteCode,
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

  /// 공유 코드로 찾기
  Future<Fridge?> findByInviteCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final snap = await _fridges
        .where('inviteCode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Fridge.fromFirestore(snap.docs.first);
  }

  /// 공유 코드 확인
  Future<String> ensureInviteCode(String fridgeId) async {
    final fridge = await get(fridgeId);
    if (fridge == null) throw StateError('냉장고를 찾을 수 없습니다.');
    final existing = fridge.inviteCode;
    if (existing != null && existing.isNotEmpty) return existing;

    final code = await _generateUniqueInviteCode();
    await _fridges.doc(fridgeId).update({
      'inviteCode': code,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    return code;
  }

  /// 멤버 추가
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
