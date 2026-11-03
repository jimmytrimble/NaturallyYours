import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'config.dart';

/// Shared, cookie-aware HTTP client. The server authenticates with a session
/// cookie (guest cart + user login), so an in-memory cookie jar is attached on
/// native platforms. On web, the browser manages cookies itself.
class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
      validateStatus: (_) => true, // we inspect status ourselves
    ));
    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(CookieJar()));
    }
  }

  static final ApiClient shared = ApiClient._();
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      _handle(await _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query}) async =>
      _handle(await _dio.post(path, data: data, queryParameters: query));

  Future<dynamic> patch(String path, {Object? data}) async =>
      _handle(await _dio.patch(path, data: data));

  Future<dynamic> delete(String path) async => _handle(await _dio.delete(path));

  /// HTTP Basic login (user/admin login endpoints).
  Future<dynamic> loginBasic(String path, String email, String password) async {
    final credentials = base64Encode(utf8.encode('$email:$password'));
    final res = await _dio.post(
      path,
      options: Options(headers: {'Authorization': 'Basic $credentials'}),
    );
    return _handle(res);
  }

  dynamic _handle(Response res) {
    final code = res.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      String? reason;
      final data = res.data;
      if (data is Map && data['reason'] is String) reason = data['reason'] as String;
      throw ApiException(code, reason ?? 'Request failed (HTTP $code)');
    }
    return res.data;
  }

  /// Resolves a product image URL: absolute URLs used as-is; server-relative
  /// paths get the API base prepended.
  static String? imageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final sep = raw.startsWith('/') ? '' : '/';
    return '${AppConfig.apiBaseUrl}$sep$raw';
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  bool get isUnauthorized => statusCode == 401;
  @override
  String toString() => message;
}
