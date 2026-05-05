import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ingredient.dart';
import '../services/auth_service.dart';
import '../services/ingredient_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';

enum RegisterMode {
  none,
  receipt,
  image,
}

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  RegisterMode mode = RegisterMode.none;
  bool hasScanned = false;
  bool showCompleteMessage = false;
  XFile? pickedImage;

  Future<void> takePicture(RegisterMode selectedMode) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    setState(() {
      mode = selectedMode;
      pickedImage = image;
      hasScanned = true;
      showCompleteMessage = false;
    });
  }

  void resetCamera() {
    setState(() {
      mode = RegisterMode.none;
      pickedImage = null;
      hasScanned = false;
      showCompleteMessage = false;
    });
  }

  Future<void> registerIngredient() async {
    final userId = AuthService.currentUser?.id ?? 'user_1';

    if (mode == RegisterMode.receipt) {
      await IngredientService.addIngredient(
        Ingredient(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: '우유',
          category: '유제품',
          emoji: '🥛',
          dday: 7,
          count: 1,
          expireDate: '2026-05-10',
          imagePath: pickedImage?.path,
        ),
      );

      await IngredientService.addIngredient(
        Ingredient(
          id: '${DateTime.now().millisecondsSinceEpoch}_2',
          userId: userId,
          name: '달걀',
          category: '신선식품',
          emoji: '🥚',
          dday: 5,
          count: 10,
          expireDate: '2026-05-08',
          imagePath: pickedImage?.path,
        ),
      );
    }

    if (mode == RegisterMode.image) {
      await IngredientService.addIngredient(
        Ingredient(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: '토마토',
          category: '채소',
          emoji: '🍅',
          dday: 6,
          count: 3,
          expireDate: '2026-05-09',
          imagePath: pickedImage?.path,
        ),
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
    return '식재료 등록';
  }

  String getGuideText() {
    if (mode == RegisterMode.receipt) {
      return 'OCR 서버에서 영수증 텍스트를 추출했습니다.';
    }

    if (mode == RegisterMode.image) {
      return 'Image Recognition 서버에서 식재료를 추측했습니다.';
    }

    return '등록 방식을 선택해주세요';
  }

  Widget getResultText() {
    if (mode == RegisterMode.receipt) {
      return const Column(
        children: [
          Text(
            '인식된 항목',
            style: TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
            ),
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
          Text(
            '분류: 유제품, 신선식품',
            style: TextStyle(color: AppColors.textSub),
          ),
        ],
      );
    }

    return const Column(
      children: [
        Text(
          '인식된 식재료',
          style: TextStyle(
            color: AppColors.textSub,
            fontSize: 13,
          ),
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
        Text(
          '분류: 채소',
          style: TextStyle(color: AppColors.textSub),
        ),
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
                    child: hasScanned ? scannedResultView() : selectModeView(),
                  ),
                ),
                if (hasScanned)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        cameraButton(() => takePicture(mode)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
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
            subtitle: '영수증 촬영 → OCR 분석 → 식재료 분류',
            icon: Icons.receipt_long,
            onTap: () => takePicture(RegisterMode.receipt),
          ),
          const SizedBox(height: 16),
          modeButton(
            title: '이미지로 등록하기',
            subtitle: '식재료 촬영 → 이미지 인식 → 종류/개수 추측',
            icon: Icons.camera_alt,
            onTap: () => takePicture(RegisterMode.image),
          ),
        ],
      ),
    );
  }

  Widget modeButton({
    required String title,
    required String subtitle,
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
                color: AppColors.mainGreen.withOpacity(0.15),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
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
              child: const Center(
                child: Icon(Icons.image, size: 80),
              ),
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

  Widget cameraButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.camera_alt, size: 34),
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
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}