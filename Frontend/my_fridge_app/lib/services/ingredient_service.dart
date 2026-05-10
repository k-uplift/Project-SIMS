import 'dart:convert';
import 'dart:io';

import '../models/ingredient.dart';
import 'auth_service.dart';

class IngredientService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String _fridgeId = 'fridge_1';
  static const String _devToken = 'dev-token';

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
    try {
      final response = await _request(
        method: 'GET',
        path: '/fridges/$_fridgeId/ingredients',
      );
      final items = jsonDecode(response) as List<dynamic>;

      return items
          .map((item) => _ingredientFromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _ingredients.where((item) => item.userId == _currentUserId).toList();
    }
  }

  static Future<List<Ingredient>> getExpiringIngredients() async {
    final ingredients = await getIngredients();
    return ingredients.where((item) => item.dday <= 7).toList();
  }

  static Future<void> addIngredient(Ingredient ingredient) async {
    try {
      await _request(
        method: 'POST',
        path: '/fridges/$_fridgeId/ingredients',
        body: _ingredientToJson(ingredient),
      );
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 300));
      _ingredients.add(ingredient);
    }
  }

  static Future<void> updateIngredient(Ingredient ingredient) async {
    try {
      await _request(
        method: 'PATCH',
        path: '/fridges/$_fridgeId/ingredients/${ingredient.id}',
        body: _ingredientToJson(ingredient),
      );
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _ingredients.indexWhere((item) => item.id == ingredient.id);

      if (index != -1) {
        _ingredients[index] = ingredient;
      }
    }
  }

  static Future<void> deleteIngredient(String id) async {
    try {
      await _request(
        method: 'DELETE',
        path: '/fridges/$_fridgeId/ingredients/$id',
      );
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 300));
      _ingredients.removeWhere((item) => item.id == id);
    }
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

  static Future<String> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);

    try {
      final request = await client.openUrl(method, Uri.parse('$_baseUrl$path'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_devToken');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(responseBody);
      }

      return responseBody;
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, dynamic> _ingredientToJson(Ingredient ingredient) {
    return {
      'name': ingredient.name,
      'category': _categoryToServer(ingredient.category),
      'emoji': ingredient.emoji,
      'count': ingredient.count,
      'expireDate': '${ingredient.expireDate}T00:00:00Z',
      'imageUrl': ingredient.imagePath,
      'addedVia': 'manual',
    };
  }

  static Ingredient _ingredientFromJson(Map<String, dynamic> json) {
    final expireDate = DateTime.parse(json['expireDate'] as String).toLocal();
    final expireDateText =
        '${expireDate.year.toString().padLeft(4, '0')}-'
        '${expireDate.month.toString().padLeft(2, '0')}-'
        '${expireDate.day.toString().padLeft(2, '0')}';

    return Ingredient(
      id: json['id'] as String,
      userId: json['addedBy'] as String? ?? _currentUserId,
      name: json['name'] as String,
      category: _categoryFromServer(json['category'] as String),
      emoji: json['emoji'] as String? ?? '🍽️',
      dday: _calculateDday(expireDate),
      count: json['count'] as int,
      expireDate: expireDateText,
      imagePath: json['imageUrl'] as String?,
    );
  }

  static int _calculateDday(DateTime expireDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expireDateOnly = DateTime(
      expireDate.year,
      expireDate.month,
      expireDate.day,
    );

    return expireDateOnly.difference(todayOnly).inDays;
  }

  static String _categoryToServer(String category) {
    switch (category) {
      case '채소':
        return '야채';
      case '과일':
      case '육류':
      case '수산물':
      case '유제품':
      case '기타':
        return category;
      case '신선식품':
        return '달걀';
      case '가공식품':
        return '기타';
      default:
        return '기타';
    }
  }

  static String _categoryFromServer(String category) {
    if (category == '야채') return '채소';
    if (category == '달걀') return '신선식품';
    return category;
  }
}
