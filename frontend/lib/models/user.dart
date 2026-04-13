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

  /// Total points balance (students only; 0 for guards/admins).
  final int totalPoints;

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
    required this.totalPoints,
    required this.createdAt,
  });

  /// Deserialises from the backend JSON payload.
  factory User.fromJson(Map<String, dynamic> json) => User(
        id:          json['id'],
        fullName:    json['fullName'],
        email:       json['email'],
        studentId:   json['studentId']   ?? '',
        plateNumber: json['plateNumber'] ?? '',
        role:        json['role'],
        isActive:    json['isActive']    ?? true,
        totalPoints: json['totalPoints'] ?? 0,
        createdAt:   DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id':          id,
        'fullName':    fullName,
        'email':       email,
        'studentId':   studentId,
        'plateNumber': plateNumber,
        'role':        role,
        'isActive':    isActive,
        'totalPoints': totalPoints,
        'createdAt':   createdAt.toIso8601String(),
      };
}
