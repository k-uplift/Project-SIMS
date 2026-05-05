import '../models/ingredient.dart';
import 'auth_service.dart';

class IngredientService {
  static final List<Ingredient> _ingredients = [
    const Ingredient(
      id: '1',
      userId: 'user_1',
      name: '우유',
      category: '유제품',
      emoji: '🥛',
      dday: 2,
      count: 1,
      expireDate: '2026-05-10',
    ),
    const Ingredient(
      id: '2',
      userId: 'user_1',
      name: '달걀',
      category: '신선식품',
      emoji: '🥚',
      dday: 3,
      count: 10,
      expireDate: '2026-05-11',
    ),
    const Ingredient(
      id: '3',
      userId: 'user_1',
      name: '양송이버섯',
      category: '채소',
      emoji: '🍄',
      dday: 5,
      count: 1,
      expireDate: '2026-05-13',
    ),
  ];

  static String get _currentUserId {
    return AuthService.currentUser?.id ?? 'user_1';
  }

  static Future<List<Ingredient>> getIngredients() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _ingredients.where((item) => item.userId == _currentUserId).toList();
  }

  static Future<List<Ingredient>> getExpiringIngredients() async {
    final ingredients = await getIngredients();
    return ingredients.where((item) => item.dday <= 7).toList();
  }

  static Future<void> addIngredient(Ingredient ingredient) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _ingredients.add(ingredient);
  }

  static Future<void> updateIngredient(Ingredient ingredient) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _ingredients.indexWhere((item) => item.id == ingredient.id);

    if (index != -1) {
      _ingredients[index] = ingredient;
    }
  }

  static Future<void> deleteIngredient(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _ingredients.removeWhere((item) => item.id == id);
  }

  static Future<Ingredient?> searchIngredient(String keyword) async {
    final ingredients = await getIngredients();

    for (final item in ingredients) {
      if (item.name.contains(keyword)) {
        return item;
      }
    }

    return null;
  }
}