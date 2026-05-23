import 'dart:convert';
import 'dart:io';

import '../models/ocr_result.dart';

class OcrService {
  OcrService._();

  static const String _baseUrl = String.fromEnvironment(
    'OCR_BASE_URL',
    defaultValue: 'http://10.0.2.2:8081',
  );

  static Future<OcrResult> analyzeImage(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const FileSystemException('이미지 파일을 찾을 수 없습니다.');
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final request = await client.postUrl(Uri.parse('$_baseUrl/ocr/text'));
      final boundary = '----sims-${DateTime.now().microsecondsSinceEpoch}';
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      final fileName = imagePath.split(Platform.pathSeparator).last;
      final mimeType = _mimeTypeFor(fileName);
      request.write('--$boundary\r\n');
      request.write(
        'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n',
      );
      request.write('Content-Type: $mimeType\r\n\r\n');
      await request.addStream(file.openRead());
      request.write('\r\n--$boundary--\r\n');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(body);
      }

      return OcrResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } finally {
      client.close(force: true);
    }
  }

  static String _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}
