import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';
import '../theme/app_colors.dart';

class IngredientDetailScreen extends StatefulWidget {
  final Ingredient ingredient;

  const IngredientDetailScreen({
    super.key,
    required this.ingredient,
  });

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  late Ingredient ingredient;
  bool isEditing = false;

  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController countController;
  late TextEditingController expireDateController;

  @override
  void initState() {
    super.initState();
    ingredient = widget.ingredient;
    nameController = TextEditingController(text: ingredient.name);
    categoryController = TextEditingController(text: ingredient.category);
    countController = TextEditingController(text: ingredient.count.toString());
    // 모델의 expireDateString (YYYY-MM-DD) 사용
    expireDateController = TextEditingController(text: ingredient.expireDateString);
  }

  Future<void> saveIngredient() async {
    // 수정한 데이터를 바탕으로 새로운 객체 생성
    final updatedIngredient = Ingredient(
      id: ingredient.id,
      fridgeId: ingredient.fridgeId,
      name: nameController.text.trim(),
      category: categoryController.text.trim(),
      emoji: ingredient.emoji,
      count: int.tryParse(countController.text.trim()) ?? ingredient.count,
      expireDate: DateTime.tryParse(expireDateController.text.trim()) ?? ingredient.expireDate,
      imageURL: ingredient.imageURL,
      addedBy: ingredient.addedBy,
      addedVia: ingredient.addedVia,
      createdAt: ingredient.createdAt,
      updatedAt: DateTime.now(), // 수정 시각 갱신
    );

    await IngredientService.updateIngredient(updatedIngredient);

    if (!mounted) return;

    setState(() {
      ingredient = updatedIngredient;
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수정되었습니다.')),
    );
  }

  Future<void> deleteIngredient() async {
    await IngredientService.deleteIngredient(ingredient.id);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Widget imageView() {
    // imageURL이 없으면 에모지 표시
    if (ingredient.imageURL == null || ingredient.imageURL!.isEmpty) {
      return Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.mainGreen.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            ingredient.emoji ?? '❓',
            style: const TextStyle(fontSize: 80),
          ),
        ),
      );
    }

    // 로컬 파일 경로인 경우 처리 (필요시 NetworkImage와 분기 로직 추가 가능)
    return ClipOval(
      child: Image.file(
        File(ingredient.imageURL!),
        width: 180,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
      ),
    );
  }

  Widget infoText(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSub,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inputField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget detailView() {
    return Column(
      children: [
        imageView(),
        const SizedBox(height: 24),
        Text(
          ingredient.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        infoText('분류', ingredient.category),
        infoText('개수', '${ingredient.count}개'),
        infoText('유통기한', ingredient.expireDateString),
        infoText('남은 기간', 'D-${ingredient.dday}'),
      ],
    );
  }

  Widget editView() {
    return Column(
      children: [
        imageView(),
        const SizedBox(height: 24),
        inputField('식재료 이름', nameController),
        inputField('분류', categoryController),
        inputField('개수', countController),
        inputField('유통기한(YYYY-MM-DD)', expireDateController),
      ],
    );
  }

  Widget bottomButtons() {
    if (isEditing) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isEditing = false;
                  // 원복
                  nameController.text = ingredient.name;
                  categoryController.text = ingredient.category;
                  countController.text = ingredient.count.toString();
                  expireDateController.text = ingredient.expireDateString;
                });
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.textSub),
                ),
                child: const Center(
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: AppColors.textSub,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: saveIngredient,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.mainGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                isEditing = true;
              });
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.mainGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  '수정',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: deleteIngredient,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.warningRed,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  '지우기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('식재료 상세'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  isEditing ? editView() : detailView(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: bottomButtons(),
            ),
          ],
        ),
      ),
    );
  }
}
