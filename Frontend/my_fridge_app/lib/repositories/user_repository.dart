import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class UserRepository {
  UserRepository._();
  static final instance = UserRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// 사용자 저장
  Future<UserProfile> createOrUpdate({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    final ref = _users.doc(uid);
    final snapshot = await ref.get();
    final now = DateTime.now();

    if (snapshot.exists) {
      await ref.update({
        'email': email,
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': Timestamp.fromDate(now),
      });
      final updated = await ref.get();
      return UserProfile.fromFirestore(updated);
    }

    final profile = UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      fridgeIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(profile.toMap());
    return profile;
  }

  Future<UserProfile?> get(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return UserProfile.fromFirestore(snapshot);
  }

  Stream<UserProfile?> watch(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromFirestore(snapshot);
    });
  }

  Future<void> addFridgeId(String uid, String fridgeId) async {
    await _users.doc(uid).update({
      'fridgeIds': FieldValue.arrayUnion([fridgeId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeFridgeId(String uid, String fridgeId) async {
    await _users.doc(uid).update({
      'fridgeIds': FieldValue.arrayRemove([fridgeId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 메인 냉장고 설정
  Future<void> setPrimaryFridge(String uid, String? fridgeId) async {
    await _users.doc(uid).update({
      'primaryFridgeId': fridgeId ?? FieldValue.delete(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
