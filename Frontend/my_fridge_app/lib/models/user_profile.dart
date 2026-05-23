import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 정보
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final List<String> fridgeIds;
  /// 현재 냉장고
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

  /// 사용할 냉장고 ID
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

/// 냉장고 정보
class Fridge {
  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;
  /// 공유 코드
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
