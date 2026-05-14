import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// 백엔드(Render) 호출 시 Firebase ID 토큰을 자동으로 Authorization 헤더에 첨부하는 클라이언트.
///
/// 사용 예:
///   final res = await ApiClient.get('/users/me');
///   final res = await ApiClient.post('/fridges', body: {'name': '내 냉장고'});
class ApiClient {
  /// Render 운영 URL. 변경 시 한 곳만 수정.
  static const String baseUrl = 'https://naengbu-server-qs2y.onrender.com';

  /// 모든 요청에 첨부할 기본 헤더 (Content-Type + 인증 토큰).
  static Future<Map<String, String>> _headers({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (requireAuth) {
      final token = await AuthService.getIdToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Uri _uri(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p');
  }

  static Future<http.Response> get(String path, {bool requireAuth = true}) async {
    return await http.get(_uri(path), headers: await _headers(requireAuth: requireAuth));
  }

  static Future<http.Response> post(
    String path, {
    Object? body,
    bool requireAuth = true,
  }) async {
    return await http.post(
      _uri(path),
      headers: await _headers(requireAuth: requireAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> patch(
    String path, {
    Object? body,
    bool requireAuth = true,
  }) async {
    return await http.patch(
      _uri(path),
      headers: await _headers(requireAuth: requireAuth),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String path, {bool requireAuth = true}) async {
    return await http.delete(_uri(path), headers: await _headers(requireAuth: requireAuth));
  }
}
