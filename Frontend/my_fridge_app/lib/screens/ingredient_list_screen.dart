import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import 'ingredient_detail_screen.dart';

class IngredientListScreen extends StatefulWidget {
  const IngredientListScreen({super.key});

  @override
  State<IngredientListScreen> createState() => _IngredientListScreenState();
}

class _IngredientListScreenState extends State<IngredientListScreen> {
  Future<List<Ingredient>>? ingredientFuture;

  @override
  void initState() {
    super.initState();
    loadIngredients();
  }

  void loadIngredients() {
    ingredientFuture = IngredientService.getIngredients();
  }

  Color ddayColor(int dday) {
    if (dday <= 2) return AppColors.warningRed;
    if (dday <= 5) return AppColors.orange;
    return AppColors.mainGreen;
  }

  Widget imageView(Ingredient item) {
    // 필드명 변경 반영 (imagePath -> imageURL)
    if (item.imageURL == null) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          // 최신 버전 권장 API 사용
          color: AppColors.mainGreen.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            item.emoji ?? '❓', // null 대비
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    return ClipOval(
      child: Image.file(
        File(item.imageURL!),
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      ),
    );
  }

  Widget categoryChip(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.mainGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> openDetail(Ingredient item) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IngredientDetailScreen(ingredient: item),
      ),
    );

    // 상세 화면에서 돌아왔을 때 목록 새로고침
    if (mounted) {
      setState(() {
        loadIngredients();
      });
    }
  }

  Widget ingredientCard(Ingredient item) {
    return GestureDetector(
      onTap: () => openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            imageView(item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.category} · ${item.count}개',
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'D-${item.dday}',
              style: TextStyle(
                color: ddayColor(item.dday),
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
      bottomNavigationBar: const BottomNav(currentIndex: 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Ingredient>>(
            future: ingredientFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
              }

              final ingredients = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '식재료 리스트',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      categoryChip('전체', true),
                      const SizedBox(width: 8),
                      categoryChip('냉장', false),
                      const SizedBox(width: 8),
                      categoryChip('냉동', false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ingredients.isEmpty
                        ? const Center(
                      child: Text(
                        '등록된 식재료가 없습니다.',
                        style: TextStyle(color: AppColors.textSub),
                      ),
                    )
                        : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          loadIngredients();
                        });
                      },
                      child: ListView.builder(
                        itemCount: ingredients.length,
                        itemBuilder: (context, index) {
                          return ingredientCard(ingredients[index]);
                        },
                      ),
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
