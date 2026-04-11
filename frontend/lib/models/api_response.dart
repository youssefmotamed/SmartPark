// api_response.dart — Generic API response wrapper matching backend ApiResponse<T>
import 'package:flutter/foundation.dart';

/// Represents the standard error payload returned by the backend.
@immutable
class ApiError {
  /// Machine-readable error code (e.g. 'NOT_FOUND', 'BADGE_SUSPENDED').
  final String code;

  /// Human-readable error message shown in the UI.
  final String message;

  /// Creates an [ApiError].
  const ApiError({required this.code, required this.message});

  /// Deserialises from the backend `error` object.
  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: json['code'] as String,
        message: json['message'] as String,
      );
}

/// Generic wrapper for every backend response envelope.
///
/// Use [fromJson] with a [fromData] converter to parse [T].
@immutable
class ApiResponse<T> {
  /// Whether the request succeeded.
  final bool success;

  /// Parsed response payload; null on error.
  final T? data;

  /// Optional human-readable success message.
  final String? message;

  /// Error detail; null on success.
  final ApiError? error;

  /// Creates an [ApiResponse].
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  /// Deserialises the JSON envelope and uses [fromData] to parse [T].
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    final errorJson = json['error'] as Map<String, dynamic>?;
    final rawData = json['data'];

    return ApiResponse<T>(
      success: json['success'] as bool,
      data: (fromData != null && rawData != null) ? fromData(rawData) : null,
      message: json['message'] as String?,
      error: errorJson != null ? ApiError.fromJson(errorJson) : null,
    );
  }
}
