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

  /// I, O, 0, 1 은 헷갈리니까 제외한 영문대문자+숫자 6자.
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// 충돌이 없을 때까지 (최대 5번) 재시도하면서 6자리 코드 생성.
  /// 32^6 ≈ 10억 조합이라 5회 안에 거의 무조건 성공.
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
    // 5번 다 충돌은 사실상 불가능. 최후의 수단으로 7자 시도.
    final rng2 = Random.secure();
    return List.generate(
      7,
          (_) => _codeAlphabet[rng2.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// 냉장고 새로 생성 (invite code 자동 발급).
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

  /// invite code로 냉장고 찾기. 없으면 null.
  /// 대소문자 무시 (사용자 입력 친화).
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

  /// 구버전 데이터(invite code 없는 냉장고)에 코드 발급. 이미 있으면 그대로 반환.
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