import 'package:cloud_firestore/cloud_firestore.dart';

/// users/{uid}
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final List<String> fridgeIds;
  /// 현재 메인으로 사용할 냉장고. null이면 fridgeIds.first 사용.
  final String? primaryFridgeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.fridgeIds,
    this.primaryFridgeId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 메인 냉장고 ID를 안전하게 가져옴.
  /// primaryFridgeId가 있고 fridgeIds에 포함되면 그걸 쓰고,
  /// 아니면 fridgeIds.first. fridgeIds가 비어있으면 null.
  String? get effectivePrimaryFridgeId {
    final pf = primaryFridgeId;
    if (pf != null && fridgeIds.contains(pf)) return pf;
    if (fridgeIds.isNotEmpty) return fridgeIds.first;
    return null;
  }

  factory UserProfile.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      fridgeIds: List<String>.from(data['fridgeIds'] ?? []),
      primaryFridgeId: data['primaryFridgeId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      'fridgeIds': fridgeIds,
      if (primaryFridgeId != null) 'primaryFridgeId': primaryFridgeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

/// fridges/{fridgeId}
class Fridge {
  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;
  /// 6자리 영문대문자+숫자 공유 코드. 가입 시 자동 발급.
  /// 구버전 데이터엔 없을 수 있어서 nullable.
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Fridge({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberUids,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Fridge.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return Fridge(
      id: doc.id,
      name: data['name'] as String? ?? '내 냉장고',
      ownerUid: data['ownerUid'] as String? ?? '',
      memberUids: List<String>.from(data['memberUids'] ?? []),
      inviteCode: data['inviteCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerUid': ownerUid,
      'memberUids': memberUids,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}