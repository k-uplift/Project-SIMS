import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeSource {
  static const llm = 'llm';
  static const saved = 'saved';
}

class Recipe {
  final String id;
  final String title;
  final String time;
  final String description;
  final List<String> ownedIngredients;
  final List<String> missingIngredients;
  final List<String> steps;

  const Recipe({
    required this.id,
    required this.title,
    required this.time,
    required this.description,
    required this.ownedIngredients,
    required this.missingIngredients,
    required this.steps,
  });

  factory Recipe.fromMap(Map<String, dynamic> data, String id) {
    return Recipe(
      id: id,
      title: data['title'] as String? ?? '',
      time: data['time'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ownedIngredients: List<String>.from(data['ownedIngredients'] ?? []),
      missingIngredients: List<String>.from(data['missingIngredients'] ?? []),
      steps: List<String>.from(data['steps'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'description': description,
      'ownedIngredients': ownedIngredients,
      'missingIngredients': missingIngredients,
      'steps': steps,
    };
  }
}

/// recipesHistory/{uid}/items/{recipeId}
class RecipeHistoryItem {
  final Recipe recipe;
  final String source;       // llm | saved
  final DateTime viewedAt;

  const RecipeHistoryItem({
    required this.recipe,
    required this.source,
    required this.viewedAt,
  });

  factory RecipeHistoryItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? {};
    return RecipeHistoryItem(
      recipe: Recipe.fromMap(data, doc.id),
      source: data['source'] as String? ?? RecipeSource.llm,
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...recipe.toMap(),
      'source': source,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }
}