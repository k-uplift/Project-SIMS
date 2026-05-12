import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ingredient.dart';
import '../services/auth_service.dart';
import '../services/ingredient_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';

enum RegisterMode { none, receipt, image, manual }

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _manualFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  final _expireDateController = TextEditingController();
  
  // 기본값을 표준 카테고리에 맞춤
  String _selectedCategory = IngredientCategory.vegetable; 
  
  RegisterMode mode = RegisterMode.none;
  bool hasScanned = false;
  bool showCompleteMessage = false;
  XFile? pickedImage;

  // 표준 카테고리 12종 사용
  static const List<String> _categories = IngredientCategory.all;

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _expireDateController.dispose();
    super.dispose();
  }

  Future<void> pickImage(RegisterMode selectedMode, ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image == null) return;

    setState(() {
      mode = selectedMode;
      pickedImage = image;
      hasScanned = true;
      showCompleteMessage = false;
    });
  }

  Future<void> pickManualImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      pickedImage = image;
      showCompleteMessage = false;
    });
  }

  void showImageSourceSheet(RegisterMode selectedMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                    Navigator.pop(context);
                    pickImage(selectedMode, ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                imageSourceTile(
                  icon: Icons.photo_library,
                  title: '앨범에서 선택',
                  onTap: () {
                    Navigator.pop(context);
                    pickImage(selectedMode, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void resetCamera() {
    setState(() {
      mode = RegisterMode.none;
      pickedImage = null;
      hasScanned = false;
      showCompleteMessage = false;
    });
  }

  void openManualForm() {
    setState(() {
      mode = RegisterMode.manual;
      pickedImage = null;
      hasScanned = false;
      showCompleteMessage = false;
    });
  }

  String emojiForCategory(String category) {
    switch (category) {
      case IngredientCategory.vegetable: return '🥬';
      case IngredientCategory.fruit: return '🍎';
      case IngredientCategory.meat: return '🥩';
      case IngredientCategory.seafood: return '🐟';
      case IngredientCategory.dairy: return '🥛';
      case IngredientCategory.egg: return '🥚';
      case IngredientCategory.snack: return '🥫';
      default: return '🍽️';
    }
  }

  // 직접 등록 로직을 새로운 Service 구조에 맞게 수정
  Future<void> registerManualIngredient() async {
    if (!(_manualFormKey.currentState?.validate() ?? false)) return;

    final expireDateStr = _expireDateController.text.trim();
    final expireDate = DateTime.tryParse(expireDateStr) ?? DateTime.now();

    await IngredientService.addIngredient(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      emoji: emojiForCategory(_selectedCategory),
      count: int.tryParse(_countController.text.trim()) ?? 1,
      expireDate: expireDate,
      imageURL: pickedImage?.path,
      addedVia: IngredientSource.manual,
    );

    setState(() {
      showCompleteMessage = true;
      _nameController.clear();
      _countController.text = '1';
      _expireDateController.clear();
      _selectedCategory = IngredientCategory.vegetable;
      pickedImage = null;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showCompleteMessage = false;
          mode = RegisterMode.none;
        });
      }
    });
  }

  Future<void> registerIngredient() async {
    if (AuthService.currentUser == null) return;

    final String source = mode == RegisterMode.receipt 
        ? IngredientSource.receipt 
        : IngredientSource.image;

    if (mode == RegisterMode.receipt) {
      await IngredientService.addIngredient(
        name: '우유',
        category: IngredientCategory.dairy,
        emoji: '🥛',
        count: 1,
        expireDate: DateTime.now().add(const Duration(days: 7)),
        imageURL: pickedImage?.path,
        addedVia: source,
      );

      await IngredientService.addIngredient(
        name: '달걀',
        category: IngredientCategory.egg,
        emoji: '🥚',
        count: 10,
        expireDate: DateTime.now().add(const Duration(days: 5)),
        imageURL: pickedImage?.path,
        addedVia: source,
      );
    } else if (mode == RegisterMode.image) {
      await IngredientService.addIngredient(
        name: '토마토',
        category: IngredientCategory.vegetable,
        emoji: '🍅',
        count: 3,
        expireDate: DateTime.now().add(const Duration(days: 6)),
        imageURL: pickedImage?.path,
        addedVia: source,
      );
    }

    setState(() {
      showCompleteMessage = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showCompleteMessage = false;
          mode = RegisterMode.none;
          pickedImage = null;
          hasScanned = false;
        });
      }
    });
  }

  String getTitle() {
    if (mode == RegisterMode.receipt) return '영수증 인식 결과';
    if (mode == RegisterMode.image) return '이미지 인식 결과';
    if (mode == RegisterMode.manual) return '직접 등록하기';
    return '식재료 등록';
  }

  String getGuideText() {
    if (mode == RegisterMode.receipt) {
      return 'OCR 서버에서 영수증 텍스트를 추출했습니다.';
    }
    if (mode == RegisterMode.image) {
      return 'Image Recognition 서버에서 식재료를 추측했습니다.';
    }
    if (mode == RegisterMode.manual) {
      return '식재료 정보를 입력해주세요';
    }
    return '등록 방식을 선택해주세요';
  }

  Widget getResultText() {
    if (mode == RegisterMode.receipt) {
      return const Column(
        children: [
          Text(
            '인식된 항목',
            style: TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
          SizedBox(height: 8),
          Text(
            '우유 1개\n달걀 10개',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          SizedBox(height: 8),
          Text('분류: 유제품, 신선식품', style: TextStyle(color: AppColors.textSub)),
        ],
      );
    }

    return const Column(
      children: [
        Text(
          '인식된 식재료',
          style: TextStyle(color: AppColors.textSub, fontSize: 13),
        ),
        SizedBox(height: 8),
        Text(
          '토마토 3개',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text('분류: 채소', style: TextStyle(color: AppColors.textSub)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: const BottomNav(currentIndex: 0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  getTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getGuideText(),
                  style: const TextStyle(color: Colors.white70),
                ),
                Expanded(
                  child: Center(
                    child: mode == RegisterMode.manual
                        ? manualRegisterView()
                        : hasScanned
                        ? scannedResultView()
                        : selectModeView(),
                  ),
                ),
                if (hasScanned)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        imageSourceButtons(),
                        const SizedBox(height: 12),
                        registerButton(),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
              ],
            ),
            if (showCompleteMessage)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.mainGreen),
                      SizedBox(width: 10),
                      Text(
                        '등록 완료',
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget selectModeView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          modeButton(
            title: '영수증으로 등록하기',
            icon: Icons.receipt_long,
            onTap: () => showImageSourceSheet(RegisterMode.receipt),
          ),
          const SizedBox(height: 16),
          modeButton(
            title: '이미지로 등록하기',
            icon: Icons.camera_alt,
            onTap: () => showImageSourceSheet(RegisterMode.image),
          ),
          const SizedBox(height: 16),
          modeButton(
            title: '직접 등록하기',
            icon: Icons.edit_note,
            onTap: openManualForm,
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

  Widget modeButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.mainGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.mainGreen, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget scannedResultView() {
    return Container(
      width: 310,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: pickedImage == null
                ? Container(
                    width: 220,
                    height: 220,
                    color: const Color(0xFFF1F1EF),
                    child: const Center(child: Icon(Icons.image, size: 80)),
                  )
                : Image.file(
                    File(pickedImage!.path),
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 16),
          getResultText(),
        ],
      ),
    );
  }

  Widget manualRegisterView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Form(
          key: _manualFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              manualTextField(
                controller: _nameController,
                label: '식재료 이름',
                hintText: '예: 양파',
                icon: Icons.eco,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '식재료 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              manualImagePicker(),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: inputDecoration(label: '분류', icon: Icons.category),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              manualTextField(
                controller: _countController,
                label: '개수',
                hintText: '예: 2',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final count = int.tryParse(value?.trim() ?? '');
                  if (count == null || count <= 0) {
                    return '1개 이상으로 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              manualTextField(
                controller: _expireDateController,
                label: '유통기한',
                hintText: 'YYYY-MM-DD',
                icon: Icons.event,
                readOnly: true,
                onTap: selectExpireDate,
                validator: (value) {
                  if (DateTime.tryParse(value?.trim() ?? '') == null) {
                    return '유통기한을 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              registerManualButton(),
              const SizedBox(height: 10),
              TextButton(
                onPressed: resetCamera,
                child: const Text(
                  '등록 방식 다시 선택',
                  style: TextStyle(color: AppColors.textSub),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> selectExpireDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;

    _expireDateController.text =
        '${pickedDate.year.toString().padLeft(4, '0')}-'
        '${pickedDate.month.toString().padLeft(2, '0')}-'
        '${pickedDate.day.toString().padLeft(2, '0')}';
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: AppColors.mainGreen),
      filled: true,
      fillColor: const Color(0xFFF7F8F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.mainGreen),
      ),
    );
  }

  Widget manualTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: inputDecoration(label: label, icon: icon, hintText: hintText),
    );
  }

  Widget manualImagePicker() {
    return GestureDetector(
      onTap: pickManualImage,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: pickedImage == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, color: AppColors.mainGreen),
                  SizedBox(height: 8),
                  Text(
                    '앨범에서 사진 선택',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '선택 사항',
                    style: TextStyle(color: AppColors.textSub, fontSize: 12),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(pickedImage!.path),
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          pickedImage = null;
                        });
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget imageSourceButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        imageSourceCircleButton(
          icon: Icons.camera_alt,
          onTap: () => pickImage(mode, ImageSource.camera),
        ),
        const SizedBox(width: 18),
        imageSourceCircleButton(
          icon: Icons.photo_library,
          onTap: () => pickImage(mode, ImageSource.gallery),
        ),
      ],
    );
  }

  Widget imageSourceCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 32),
      ),
    );
  }

  Widget registerButton() {
    return GestureDetector(
      onTap: registerIngredient,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.mainGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            '식재료 등록하기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget registerManualButton() {
    return GestureDetector(
      onTap: registerManualIngredient,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.mainGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            '직접 등록하기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
