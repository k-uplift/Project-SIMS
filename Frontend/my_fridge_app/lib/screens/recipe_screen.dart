import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import 'recipe_detail_screen.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});

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
                    '보유: ${recipe.ownedIngredients.join(', ')} / 부족: ${recipe.missingIngredients.join(', ')}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const BottomNav(currentIndex: 4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Recipe>>(
            future: RecipeService.getRecipes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final recipes = snapshot.data!;

              return Column(
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
                    '보유 식재료를 기반으로 추천된 요리입니다.',
                    style: TextStyle(color: AppColors.textSub),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: recipes
                          .map((recipe) => recipeCard(context, recipe))
                          .toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}