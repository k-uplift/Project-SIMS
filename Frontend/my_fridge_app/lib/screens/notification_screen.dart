import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Color ddayColor(int dday) {
    if (dday <= 2) return AppColors.warningRed;
    if (dday <= 5) return AppColors.orange;
    return AppColors.mainGreen;
  }

  Widget imageView(Ingredient item) {
    // 이미지가 없을 경우 에모지 표시
    if (item.imageURL == null || item.imageURL!.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.mainGreen.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            item.emoji ?? '❓',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      );
    }

    // 이미지가 있을 경우 표시
    return ClipOval(
      child: Image.file(
        File(item.imageURL!),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.broken_image, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const BottomNav(currentIndex: 2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Ingredient>>(
            future: IngredientService.getExpiringIngredients(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
              }

              final items = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '알림',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '유통기한이 임박한 식재료입니다.',
                    style: TextStyle(color: AppColors.textSub),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(child: Text('알림이 없습니다.'))
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];

                              return Container(
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
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '유통기한 ${item.dday}일 남았습니다',
                                            style: const TextStyle(
                                              color: AppColors.textSub,
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
                              );
                            },
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
