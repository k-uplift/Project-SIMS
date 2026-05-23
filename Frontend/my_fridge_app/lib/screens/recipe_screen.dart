import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../services/ingredient_service.dart';
import '../services/recipe_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import 'recipe_detail_screen.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  bool isLoading = false;
  String? errorMessage;
  List<Ingredient> ingredients = [];
  List<Recipe> recipes = [];

  @override
  void initState() {
    super.initState();
    loadInitialState();
  }

  Future<void> loadInitialState() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedIngredients = await IngredientService.getIngredients();
      final loadedRecipes = loadedIngredients.isEmpty
          ? <Recipe>[]
          : await RecipeService.recommendRecipes();

      if (!mounted) return;

      setState(() {
        ingredients = loadedIngredients;
        recipes = loadedRecipes;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = '추천을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> refreshRecommendations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedIngredients = await IngredientService.getIngredients();

      if (loadedIngredients.isEmpty) {
        if (!mounted) return;
        setState(() {
          ingredients = loadedIngredients;
          recipes = [];
          isLoading = false;
        });
        return;
      }

      final recommendedRecipes = await RecipeService.recommendRecipes();

      if (!mounted) return;

      setState(() {
        ingredients = loadedIngredients;
        recipes = recommendedRecipes;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = '추천을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  Widget recipeCard(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.mainGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: AppColors.mainGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '보유: ${displayList(recipe.ownedIngredients)}',
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '부족: ${displayList(recipe.missingIngredients)}',
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              recipe.time,
              style: const TextStyle(
                color: AppColors.deepGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String displayList(List<String> items) {
    if (items.isEmpty) return '없음';
    return items.join(', ');
  }

  Widget ingredientSummary() {
    if (ingredients.isEmpty) {
      return const SizedBox();
    }

    final names = ingredients.take(5).map((item) => item.name).join(', ');
    final extraCount = ingredients.length - 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        extraCount > 0 ? '보유 식재료: $names 외 $extraCount개' : '보유 식재료: $names',
        style: const TextStyle(
          color: AppColors.textSub,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget recommendButton() {
    return GestureDetector(
      onTap: isLoading ? null : refreshRecommendations,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey : AppColors.mainGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '보유 식재료로 추천받기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget emptyIngredientView() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          '등록된 식재료가 없습니다.\n식재료를 먼저 등록하면 추천을 받을 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSub, height: 1.5),
        ),
      ),
    );
  }

  Widget errorView() {
    if (errorMessage == null) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        errorMessage!,
        style: const TextStyle(
          color: AppColors.warningRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget recipeList() {
    if (isLoading && recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ingredients.isEmpty) {
      return emptyIngredientView();
    }

    if (recipes.isEmpty) {
      return const Center(
        child: Text(
          '추천 결과가 없습니다.',
          style: TextStyle(color: AppColors.textSub),
        ),
      );
    }

    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return recipeCard(context, recipes[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const BottomNav(currentIndex: 4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '레시피 추천',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '보유 식재료와 유통기한을 기준으로 추천합니다.',
                style: TextStyle(color: AppColors.textSub),
              ),
              const SizedBox(height: 16),
              ingredientSummary(),
              if (ingredients.isNotEmpty) const SizedBox(height: 12),
              recommendButton(),
              const SizedBox(height: 12),
              errorView(),
              Expanded(child: recipeList()),
            ],
          ),
        ),
      ),
    );
  }
}
