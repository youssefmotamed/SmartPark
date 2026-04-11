// auth_response.dart — Parses login and token refresh API responses
import 'package:flutter/foundation.dart';

/// Lightweight user info embedded in the login/refresh response.
///
/// Full profile details are fetched separately via GET /api/v1/profile.
@immutable
class AuthUser {
  final int    id;
  final String fullName;
  final String role;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id:       json['id'],
        fullName: json['fullName'],
        role:     json['role'],
      );
}

/// Full response from POST /auth/login and POST /auth/refresh.
@immutable
class AuthResponse {
  final String   accessToken;
  final String   refreshToken;
  final String   tokenType;
  final int      expiresIn;
  final AuthUser user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken:  json['accessToken'],
        refreshToken: json['refreshToken'],
        tokenType:    json['tokenType']  ?? 'Bearer',
        expiresIn:    json['expiresIn']  ?? 3600,
        user:         AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
