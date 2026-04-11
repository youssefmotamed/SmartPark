// user.dart — Data model for a SmartPark user account
import 'package:flutter/foundation.dart';

/// Represents a registered SmartPark user (student, guard, or admin).
@immutable
class User {
  /// Database ID.
  final int id;

  /// Full display name.
  final String fullName;

  /// Login email address.
  final String email;

  /// University student ID (empty string for guards/admins).
  final String studentId;

  /// Vehicle plate number.
  final String plateNumber;

  /// Role string: 'STUDENT', 'GUARD', or 'ADMIN'.
  final String role;

  /// Whether the account is active.
  final bool isActive;

  /// Account creation timestamp.
  final DateTime createdAt;

  /// Creates a [User].
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.studentId,
    required this.plateNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  /// Deserialises from the backend JSON payload.
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        studentId: json['student_id'] as String? ?? '',
        plateNumber: json['plate_number'] as String? ?? '',
        role: json['role'] as String,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
