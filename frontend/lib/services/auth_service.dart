// auth_service.dart — Calls the SmartPark auth API (login, register, refresh)
import 'base_api_service.dart';

/// Parsed result of a successful login or token refresh.
class AuthResult {
  final String accessToken;
  final String refreshToken;
  final int    userId;
  final String fullName;
  final String role;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    required this.role,
  });

  factory AuthResult.fromJson(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    return AuthResult(
      accessToken:  data['accessToken']  as String,
      refreshToken: data['refreshToken'] as String,
      userId:       user['id']           as int,
      fullName:     user['fullName']     as String,
      role:         user['role']         as String,
    );
  }
}

class AuthService extends BaseApiService {
  /// Authenticates with [email] and [password].
  /// Returns an [AuthResult] on success, throws [ApiException] on failure.
  Future<AuthResult> login(String email, String password) async {
    final response = await post('/auth/login', body: {
      'email':    email,
      'password': password,
    });
    return AuthResult.fromJson(response['data'] as Map<String, dynamic>);
  }
}
