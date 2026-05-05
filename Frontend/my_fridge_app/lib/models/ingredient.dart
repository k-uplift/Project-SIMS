class Ingredient {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String emoji;
  final int dday;
  final int count;
  final String expireDate;
  final String? imagePath;

  const Ingredient({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.emoji,
    required this.dday,
    required this.count,
    required this.expireDate,
    this.imagePath,
  });
}