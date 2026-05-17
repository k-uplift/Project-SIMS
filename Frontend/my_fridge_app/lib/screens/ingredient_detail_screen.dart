import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';
import '../services/storage_service.dart';
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
  XFile? pickedImage;

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
    expireDateController = TextEditingController(text: ingredient.expireDateString);
  }

  Future<void> saveIngredient() async {
    final editedIngredient = Ingredient(
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
      updatedAt: DateTime.now(),
    );

    final updatedIngredient = await IngredientService.updateIngredient(
      editedIngredient,
      imageLocalPath: pickedImage?.path,
    );

    if (!mounted) return;

    setState(() {
      ingredient = updatedIngredient;
      pickedImage = null;
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수정되었습니다.')),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    countController.dispose();
    expireDateController.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      pickedImage = image;
    });
  }

  void showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                imageSourceTile(
                  icon: Icons.camera_alt,
                  title: '사진 촬영',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                imageSourceTile(
                  icon: Icons.photo_library,
                  title: '앨범에서 선택',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteIngredient() async {
    await IngredientService.deleteIngredient(ingredient.id);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  Widget imageView() {
    final url = pickedImage?.path ?? ingredient.imageURL;

    if (url == null || url.isEmpty) {
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

    final imageProvider = StorageService.isRemoteUrl(url)
        ? NetworkImage(url) as ImageProvider
        : FileImage(File(url));

    return ClipOval(
      child: Image(
        image: imageProvider,
        width: 180,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.mainGreen.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.broken_image, size: 80),
        ),
      ),
    );
  }

  Widget editableImageView() {
    return GestureDetector(
      onTap: showImageSourceSheet,
      child: Stack(
        alignment: Alignment.center,
        children: [
          imageView(),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.mainGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget imageSourceTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.mainGreen),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMain,
          fontWeight: FontWeight.bold,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        infoText('남은 기간', ingredient.ddayLabel),
      ],
    );
  }

  Widget editView() {
    return Column(
      children: [
        editableImageView(),
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
                  pickedImage = null;
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
                pickedImage = null;
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
