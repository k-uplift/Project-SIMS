import 'package:cloud_firestore/cloud_firestore.dart';

/// users/{uid}
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final List<String> fridgeIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.fridgeIds,
    required this.createdAt,
    required this.updatedAt,
  });

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
  final DateTime createdAt;
  final DateTime updatedAt;

  const Fridge({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.memberUids,
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerUid': ownerUid,
      'memberUids': memberUids,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}