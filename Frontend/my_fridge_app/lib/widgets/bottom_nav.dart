import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/home_screen.dart';
import '../screens/ingredient_list_screen.dart';
import '../screens/ocr_screen.dart';
import '../screens/llm_screen.dart';
import '../screens/recipe_screen.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({super.key, required this.currentIndex});

  void move(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ['식재료 등록', Icons.add_circle_outline, const OcrScreen()],
      ['식재료 리스트', Icons.list_alt, const IngredientListScreen()],
      ['홈', Icons.home, const HomeScreen()],
      ['LLM', Icons.smart_toy_outlined, const LlmScreen()],
      ['레시피 추천', Icons.restaurant_menu, const RecipeScreen()],
    ];

    return Container(
      height: 82,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECECEC))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final active = index == currentIndex;

          return GestureDetector(
            onTap: () => move(context, items[index][2] as Widget),
            child: SizedBox(
              width: 70,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[index][1] as IconData,
                    color: active ? AppColors.mainGreen : Colors.grey,
                    size: 25,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index][0] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.mainGreen : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}