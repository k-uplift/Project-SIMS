import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme/app_colors.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(recipe.title),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.mainGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.restaurant_menu,
                size: 80,
                color: AppColors.mainGreen,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            recipe.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recipe.description,
            style: const TextStyle(
              color: AppColors.textSub,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '소요 시간: ${recipe.time}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '보유한 재료',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.ownedIngredients
                .map(
                  (item) => Chip(
                label: Text(item),
                backgroundColor: AppColors.mainGreen.withOpacity(0.15),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            '구매해야 하는 재료',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.missingIngredients
                .map(
                  (item) => Chip(
                label: Text(item),
                backgroundColor: AppColors.orange.withOpacity(0.2),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            '조리 방법',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...recipe.steps.asMap().entries.map(
                (entry) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${entry.key + 1}. ${entry.value}',
                style: const TextStyle(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}