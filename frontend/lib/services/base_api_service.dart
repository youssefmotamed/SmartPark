// base_api_service.dart — HTTP base class with JWT injection, error handling, and token cleanup
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Thrown whenever the backend returns a non-2xx status code.
class ApiException implements Exception {
  /// HTTP status code.
  final int statusCode;

  /// Machine-readable error code from the backend.
  final String code;

  /// Human-readable message safe to show in the UI.
  final String message;

  /// Creates an [ApiException].
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Base class for all API service classes.
///
/// Injects JWT tokens, handles timeouts, parses error envelopes,
/// and clears stored credentials on 401 responses.
class BaseApiService {
  final String _baseUrl = ApiConfig.baseUrl;
  final Duration _timeout = Duration(seconds: ApiConfig.timeoutSeconds);

  /// Builds the standard request headers, injecting the Bearer token if present.
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Removes all auth-related keys from SharedPreferences (called on 401).
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(ApiConfig.tokenKey),
      prefs.remove(ApiConfig.refreshTokenKey),
      prefs.remove(ApiConfig.userRoleKey),
      prefs.remove(ApiConfig.userIdKey),
    ]);
  }

  /// Decodes an error response and throws an [ApiException]. Never returns.
  Never _handleError(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }
    final error = body['error'] as Map<String, dynamic>?;
    throw ApiException(
      statusCode: response.statusCode,
      code: error?['code'] as String? ?? 'UNKNOWN',
      message: error?['message'] as String? ?? 'An unexpected error occurred.',
    );
  }

  /// Performs a GET request to [path].
  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .get(uri, headers: await _getHeaders())
        .timeout(_timeout);
    if (response.statusCode == 401) await _clearTokens();
    if (response.statusCode >= 400) _handleError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Performs a POST request to [path] with an optional JSON [body].
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .post(uri, headers: await _getHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    if (response.statusCode == 401) await _clearTokens();
    if (response.statusCode >= 400) _handleError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Performs a PUT request to [path] with an optional JSON [body].
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .put(uri, headers: await _getHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    if (response.statusCode == 401) await _clearTokens();
    if (response.statusCode >= 400) _handleError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Performs a PATCH request to [path] with an optional JSON [body].
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .patch(uri, headers: await _getHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    if (response.statusCode == 401) await _clearTokens();
    if (response.statusCode >= 400) _handleError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Performs a DELETE request to [path].
  ///
  /// Returns `{'success': true}` on 204 No Content, otherwise decodes the body.
  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http
        .delete(uri, headers: await _getHeaders())
        .timeout(_timeout);
    if (response.statusCode == 401) await _clearTokens();
    if (response.statusCode >= 400) _handleError(response);
    if (response.statusCode == 204) return {'success': true};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
