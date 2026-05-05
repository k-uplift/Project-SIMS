import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ShareFridgeScreen extends StatefulWidget {
  const ShareFridgeScreen({super.key});

  @override
  State<ShareFridgeScreen> createState() => _ShareFridgeScreenState();
}

class _ShareFridgeScreenState extends State<ShareFridgeScreen> {
  final codeController = TextEditingController();
  String message = '';

  void joinFridge() {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      showMessage('공유 코드를 입력해주세요.');
      return;
    }

    showMessage('공유 냉장고에 참여했습니다.');
  }

  void showMessage(String text) {
    setState(() {
      message = text;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          message = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const myShareCode = 'FRIDGE-2026';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('냉장고 공유'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '내 냉장고 공유 코드',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      myShareCode,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainGreen,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '같은 냉장고를 공유할 사용자에게 이 코드를 알려주세요.',
                    style: TextStyle(color: AppColors.textSub),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: '공유 코드 입력',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: joinFridge,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.mainGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    '공유 냉장고 참여하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}