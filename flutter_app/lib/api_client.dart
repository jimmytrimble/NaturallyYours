import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

/// Thin wrapper over the REST API. Read-only for now (catalog); a cookie-aware
/// client (dio + cookie_jar) will be added when we port cart/auth.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// GET a JSON endpoint and decode it.
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path').replace(
      queryParameters: query,
    );
    final res = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, _reason(res.body));
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  /// Resolves a product image URL: absolute URLs are used as-is; server-relative
  /// paths (e.g. /uploads/...) get the API base prepended.
  static String? imageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final sep = raw.startsWith('/') ? '' : '/';
    return '${AppConfig.apiBaseUrl}$sep$raw';
  }

  String _reason(String body) {
    try {
      final obj = jsonDecode(body);
      if (obj is Map && obj['reason'] is String) return obj['reason'] as String;
    } catch (_) {}
    return 'Request failed';
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}
