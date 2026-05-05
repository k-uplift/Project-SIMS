import '../models/recipe.dart';

class RecipeService {
  static final List<Recipe> _recipes = [
    const Recipe(
      id: '1',
      title: '계란 볶음밥',
      time: '15분',
      description: '달걀을 활용해 간단하게 만들 수 있는 볶음밥입니다.',
      ownedIngredients: ['달걀'],
      missingIngredients: ['밥', '대파'],
      steps: [
        '팬에 기름을 두르고 달걀을 풀어 스크램블을 만듭니다.',
        '밥을 넣고 함께 볶습니다.',
        '간장과 소금으로 간을 맞춥니다.',
        '대파를 넣고 마무리합니다.',
      ],
    ),
    const Recipe(
      id: '2',
      title: '크림 파스타',
      time: '25분',
      description: '우유를 활용해 부드럽게 만들 수 있는 크림 파스타입니다.',
      ownedIngredients: ['우유'],
      missingIngredients: ['파스타면', '베이컨'],
      steps: [
        '파스타면을 삶습니다.',
        '팬에 베이컨과 양파를 볶습니다.',
        '우유를 넣고 끓입니다.',
        '삶은 면을 넣고 소스를 졸입니다.',
      ],
    ),
    const Recipe(
      id: '3',
      title: '버섯 된장찌개',
      time: '20분',
      description: '버섯을 활용한 따뜻한 된장찌개입니다.',
      ownedIngredients: ['양송이버섯'],
      missingIngredients: ['된장', '두부', '애호박'],
      steps: [
        '물에 된장을 풀고 끓입니다.',
        '버섯과 채소를 넣습니다.',
        '두부를 넣고 한 번 더 끓입니다.',
        '간을 맞춘 후 완성합니다.',
      ],
    ),
  ];

  static Future<List<Recipe>> getRecipes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_recipes);
  }

  static Future<Recipe?> searchRecipe(String keyword) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (final recipe in _recipes) {
      if (recipe.title.contains(keyword)) {
        return recipe;
      }
    }

    return null;
  }

  static Future<Recipe?> getRecipeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (final recipe in _recipes) {
      if (recipe.id == id) {
        return recipe;
      }
    }

    return null;
  }
}