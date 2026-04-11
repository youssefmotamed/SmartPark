// auth_service.dart — Authentication API calls: register, login, refresh
import '../models/auth_response.dart';
import 'base_api_service.dart';

/// Handles all authentication endpoints.
///
/// Extends [BaseApiService] for JWT injection and unified error handling.
class AuthService extends BaseApiService {
  /// Registers a new student account.
  ///
  /// Throws [ApiException] on 409 (duplicate email/studentId) or 400 (validation).
  Future<void> register({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
    required String plateNumber,
  }) async {
    await post('/auth/register', body: {
      'fullName':    fullName,
      'studentId':   studentId,
      'email':       email,
      'password':    password,
      'plateNumber': plateNumber,
    });
  }

  /// Logs in a user and returns tokens + basic user info.
  ///
  /// Throws [ApiException] on 401 (wrong credentials) or 422 (deactivated).
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/login', body: {
      'email':    email,
      'password': password,
    });
    return AuthResponse.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Exchanges a refresh token for a new access + refresh token pair.
  ///
  /// Throws [ApiException] on 422 (expired or invalid refresh token).
  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await post('/auth/refresh', body: {
      'refreshToken': refreshToken,
    });
    return AuthResponse.fromJson(response['data'] as Map<String, dynamic>);
  }
}
