import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../services/fridge_service.dart';
import '../services/ingredient_service.dart';
import '../services/recipe_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import 'ingredient_list_screen.dart';
import 'notification_screen.dart';
import 'recipe_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final searchController = TextEditingController();
  String searchMessage = '';

  // 냉장고 선택용 상태
  List<FridgeView> myFridges = [];
  String? currentFridgeId;
  bool loadingFridges = true;

  // 화면 갱신 트리거. 냉장고 바뀌면 이 키를 새로 만들어서
  // FutureBuilder들이 다시 fetch하도록 함.
  Key dataKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    loadFridges();
  }

  Future<void> loadFridges() async {
    final list = await FridgeService.myFridges();
    final current = await FridgeService.currentFridgeId();
    if (!mounted) return;
    setState(() {
      myFridges = list;
      currentFridgeId = current;
      loadingFridges = false;
    });
  }

  Future<void> selectFridge(FridgeView view) async {
    if (view.id == currentFridgeId) return;
    await FridgeService.setPrimaryFridge(view.id);
    if (!mounted) return;
    setState(() {
      currentFridgeId = view.id;
      // 유통기한 임박 / 알림 배지가 새 냉장고 기준으로 갱신되도록
      dataKey = UniqueKey();
    });
  }

  Future<void> search() async {
    final keyword = searchController.text.trim();

    if (keyword.isEmpty) return;

    final ingredient = await IngredientService.searchIngredient(keyword);

    if (!mounted) return;

    if (ingredient != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const IngredientListScreen(),
        ),
      );
      return;
    }

    final recipe = await RecipeService.searchRecipe(keyword);

    if (!mounted) return;

    if (recipe != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: recipe),
        ),
      );
      return;
    }

    setState(() {
      searchMessage = '해당 식재료 또는 레시피가 없습니다';
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          searchMessage = '';
        });
      }
    });
  }

  /// 헤더 부제목: 냉장고 0개면 '냉장고', 1개면 단순 텍스트, 2개+면 드롭다운.
  Widget fridgeHeader() {
    const baseStyle = TextStyle(
      color: AppColors.textSub,
      fontWeight: FontWeight.bold,
    );

    if (loadingFridges) {
      return const Text('', style: baseStyle);
    }

    if (myFridges.isEmpty) {
      return const Text('냉장고', style: baseStyle);
    }

    final current = myFridges.firstWhere(
          (v) => v.id == currentFridgeId,
      orElse: () => myFridges.first,
    );

    if (myFridges.length <= 1) {
      return Text(current.displayName, style: baseStyle);
    }

    return InkWell(
      onTap: showFridgePicker,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                current.displayName,
                style: baseStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.expand_more,
              size: 18,
              color: AppColors.textSub,
            ),
          ],
        ),
      ),
    );
  }

  void showFridgePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '냉장고 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...myFridges.map((view) {
                  final selected = view.id == currentFridgeId;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      selectFridge(view);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.mainGreen.withValues(alpha: 0.1)
                            : const Color(0xFFF5F5F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.mainGreen
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? AppColors.mainGreen
                                : AppColors.textSub,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  view.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? AppColors.deepGreen
                                        : AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${view.memberCount}명 사용 중',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget expiringCard(List<Ingredient> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('유통기한이 임박한 식재료가 없습니다.'),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              items.map((item) => '${item.name} ${item.count}개 (D-${item.dday})').join('\n'),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget recipeCard(Recipe recipe) {
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.mainGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${recipe.title} 추천!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              recipe.time,
              style: const TextStyle(color: Colors.white),
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
      bottomNavigationBar: const BottomNav(currentIndex: 2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '냉장고를 부탁해',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Row(
                    children: [
                      FutureBuilder(
                        key: ValueKey('badge-$dataKey'),
                        future: IngredientService.getExpiringIngredients(),
                        builder: (context, snapshot) {
                          final notificationCount = snapshot.data?.length ?? 0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              );
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none, size: 26),
                                if (notificationCount > 0)
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$notificationCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: const Icon(Icons.settings, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              fridgeHeader(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey),
                          hintText: '식재료 또는 레시피 검색',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onSubmitted: (_) => search(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: search,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.mainGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          '검색',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (searchMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    searchMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 25),
              const Text(
                '유통기한 임박',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Ingredient>>(
                key: ValueKey('expiring-$dataKey'),
                future: IngredientService.getExpiringIngredients(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  return expiringCard(items);
                },
              ),
              const SizedBox(height: 25),
              const Text(
                '추천 레시피',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Recipe>>(
                key: ValueKey('recipe-$dataKey'),
                future: RecipeService.getRecipes(),
                builder: (context, snapshot) {
                  final recipes = snapshot.data ?? [];

                  if (recipes.isEmpty) {
                    return const Text('추천 레시피가 없습니다.');
                  }

                  return Column(
                    children: recipes.take(2).map(recipeCard).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
