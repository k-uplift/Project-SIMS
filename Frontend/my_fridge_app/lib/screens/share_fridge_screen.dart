import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/fridge_service.dart';
import '../theme/app_colors.dart';

class ShareFridgeScreen extends StatefulWidget {
  const ShareFridgeScreen({super.key});

  @override
  State<ShareFridgeScreen> createState() => _ShareFridgeScreenState();
}

class _ShareFridgeScreenState extends State<ShareFridgeScreen> {
  final codeController = TextEditingController();
  String message = '';
  bool isJoining = false;

  String? myCode;
  bool loadingMyCode = true;

  @override
  void initState() {
    super.initState();
    loadMyCode();
  }

  Future<void> loadMyCode() async {
    try {
      final code = await FridgeService.myInviteCode();
      if (!mounted) return;
      setState(() {
        myCode = code;
        loadingMyCode = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[ShareFridge] loadMyCode 실패: $e');
      if (!mounted) return;
      setState(() {
        loadingMyCode = false;
      });
    }
  }

  Future<void> joinFridge() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      showMessage('공유 코드를 입력해주세요.');
      return;
    }
    if (isJoining) return;

    setState(() {
      isJoining = true;
    });

    final result = await FridgeService.joinByCode(code);

    if (!mounted) return;

    setState(() {
      isJoining = false;
    });

    switch (result) {
      case JoinFridgeResult.success:
        showMessage('공유 냉장고에 참여했습니다.');
        codeController.clear();
        break;
      case JoinFridgeResult.alreadyMember:
        showMessage('이미 참여 중인 냉장고입니다.');
        break;
      case JoinFridgeResult.codeNotFound:
        showMessage('해당 코드의 냉장고를 찾을 수 없습니다.');
        break;
      case JoinFridgeResult.notLoggedIn:
        showMessage('로그인이 필요합니다.');
        break;
    }
  }

  Future<void> copyMyCode() async {
    final code = myCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    showMessage('공유 코드를 복사했습니다.');
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

  Widget myCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 냉장고 공유 코드',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: loadingMyCode
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
                : Text(
              myCode ?? '코드를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: myCode != null
                    ? AppColors.mainGreen
                    : AppColors.textSub,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (myCode != null)
            Center(
              child: GestureDetector(
                onTap: copyMyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mainGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: AppColors.mainGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '코드 복사',
                        style: TextStyle(
                          color: AppColors.mainGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            '같은 냉장고를 공유할 사용자에게 이 코드를 알려주세요.',
            style: TextStyle(color: AppColors.textSub, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            myCodeCard(),
            const SizedBox(height: 18),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: '공유 코드 입력 (예: K3F9XQ)',
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
              onTap: isJoining ? null : joinFridge,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: isJoining
                      ? AppColors.mainGreen.withValues(alpha: 0.5)
                      : AppColors.mainGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: isJoining
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : const Text(
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