import 'package:cloud_firestore/cloud_firestore.dart';

/// 식재료 카테고리
class IngredientCategory {
  static const vegetable = '야채';
  static const fruit = '과일';
  static const meat = '육류';
  static const seafood = '수산물';
  static const dairy = '유제품';
  static const egg = '달걀';
  static const grainNoodle = '곡물/면';
  static const sauce = '조미료/소스';
  static const beverage = '음료';
  static const frozen = '냉동식품';
  static const snack = '간식/과자';
  static const other = '기타';

  static const all = [
    vegetable, fruit, meat, seafood, dairy, egg,
    grainNoodle, sauce, beverage, frozen, snack, other,
  ];
}

class IngredientSource {
  static const manual = 'manual';
  static const receipt = 'receipt';
  static const image = 'image';
}

class Ingredient {
  final String id;
  final String fridgeId;
  final String name;
  final String category;
  final String? emoji;
  final int count;
  final DateTime expireDate;
  final String? imageURL;
  final String addedBy;
  final String addedVia;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ingredient({
    required this.id,
    required this.fridgeId,
    required this.name,
    required this.category,
    this.emoji,
    required this.count,
    required this.expireDate,
    this.imageURL,
    required this.addedBy,
    required this.addedVia,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 남은 일수
  int get dday {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final exp = DateTime(expireDate.year, expireDate.month, expireDate.day);
    return exp.difference(today).inDays;
  }

  String get ddayLabel {
    if (dday < 0) return '유통기한 만료';
    return 'D-$dday';
  }

  String get ddayDescription {
    if (dday < 0) return '유통기한이 만료되었습니다';
    return '유통기한 $dday일 남았습니다';
  }

  /// 유통기한 표시
  String get expireDateString {
    return '${expireDate.year}-'
        '${expireDate.month.toString().padLeft(2, '0')}-'
        '${expireDate.day.toString().padLeft(2, '0')}';
  }

  factory Ingredient.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      String fridgeId,
      ) {
    final data = doc.data() ?? {};
    return Ingredient(
      id: doc.id,
      fridgeId: fridgeId,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? IngredientCategory.other,
      emoji: data['emoji'] as String?,
      count: (data['count'] as num?)?.toInt() ?? 1,
      expireDate: (data['expireDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageURL: data['imageURL'] as String?,
      addedBy: data['addedBy'] as String? ?? '',
      addedVia: data['addedVia'] as String? ?? IngredientSource.manual,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      if (emoji != null) 'emoji': emoji,
      'count': count,
      'expireDate': Timestamp.fromDate(expireDate),
      if (imageURL != null) 'imageURL': imageURL,
      'addedBy': addedBy,
      'addedVia': addedVia,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Ingredient copyWith({
    String? name,
    String? category,
    String? emoji,
    int? count,
    DateTime? expireDate,
    String? imageURL,
  }) {
    return Ingredient(
      id: id,
      fridgeId: fridgeId,
      name: name ?? this.name,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      expireDate: expireDate ?? this.expireDate,
      imageURL: imageURL ?? this.imageURL,
      addedBy: addedBy,
      addedVia: addedVia,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
