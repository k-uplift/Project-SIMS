import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// 이미지 저장 서비스
class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static String _ingredientPath({
    required String fridgeId,
    required String ingredientId,
  }) {
    return 'fridges/$fridgeId/ingredients/$ingredientId.jpg';
  }

  /// 식재료 이미지 업로드
  static Future<String?> uploadIngredientImage({
    required String fridgeId,
    required String ingredientId,
    required String localFilePath,
  }) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) return null;

      final ref = _storage.ref(_ingredientPath(
        fridgeId: fridgeId,
        ingredientId: ingredientId,
      ));

      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print('[StorageService] uploadIngredientImage 실패: $e');
      return null;
    }
  }

  /// 식재료 이미지 삭제
  static Future<void> deleteIngredientImage({
    required String fridgeId,
    required String ingredientId,
  }) async {
    try {
      await _storage
          .ref(_ingredientPath(
        fridgeId: fridgeId,
        ingredientId: ingredientId,
      ))
          .delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return; // 없으면 무시
      // ignore: avoid_print
      print('[StorageService] deleteIngredientImage 실패: $e');
    } catch (e) {
      // ignore: avoid_print
      print('[StorageService] deleteIngredientImage 실패: $e');
    }
  }

  /// URL 이미지인지 확인
  static bool isRemoteUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
