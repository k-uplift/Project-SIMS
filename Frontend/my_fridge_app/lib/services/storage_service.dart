import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage 업로드/삭제를 캡슐화.
///
/// 경로 규칙: fridges/{fridgeId}/ingredients/{ingredientId}.jpg
/// (냉장고 단위로 묶어서 공유 멤버 권한 관리를 쉽게 한다)
class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static String _ingredientPath({
    required String fridgeId,
    required String ingredientId,
  }) {
    return 'fridges/$fridgeId/ingredients/$ingredientId.jpg';
  }

  /// 식재료 이미지를 업로드하고 다운로드 URL을 반환.
  /// 실패 시 null 반환 (호출부에서 "이미지 없이 등록" 분기 처리).
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
      // 네트워크 / 권한 / 파일 깨짐 등 모든 경우를 묶어서 null.
      // ignore: avoid_print
      print('[StorageService] uploadIngredientImage 실패: $e');
      return null;
    }
  }

  /// 식재료 삭제 시 Storage에 남은 이미지도 정리.
  /// 이미지가 없거나 이미 삭제된 경우는 조용히 무시.
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
      if (e.code == 'object-not-found') return; // 원래 없으면 OK
      // ignore: avoid_print
      print('[StorageService] deleteIngredientImage 실패: $e');
    } catch (e) {
      // ignore: avoid_print
      print('[StorageService] deleteIngredientImage 실패: $e');
    }
  }

  /// 외부 URL인지 (Firebase Storage가 발급한 downloadURL 등) 판별.
  /// 화면에서 Image.network vs Image.file 분기에 사용.
  static bool isRemoteUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }
}