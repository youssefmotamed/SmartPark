// api_config.dart — API base URL and SharedPreferences key constants
import 'package:flutter/foundation.dart';

/// API configuration — all network and storage key constants live here.
@immutable
class ApiConfig {
  const ApiConfig._();

  /// Backend base URL.
  /// iOS Simulator: localhost resolves to Mac directly.
  /// Android emulator: use 10.0.2.2. Physical device: use machine's LAN IP.
  static const String baseUrl = 'http://192.168.1.14:8080/api/v1';

  /// HTTP request timeout in seconds.
  static const int timeoutSeconds = 30;

  /// SharedPreferences key for the JWT access token.
  static const String tokenKey = 'access_token';

  /// SharedPreferences key for the JWT refresh token.
  static const String refreshTokenKey = 'refresh_token';

  /// SharedPreferences key for the logged-in user's role string.
  static const String userRoleKey = 'user_role';

  /// SharedPreferences key for the logged-in user's ID.
  static const String userIdKey = 'user_id';
}
