// admin_user.dart — User model for GET /admin/users and GET /admin/users/{id}.

/// Full user record as seen by an admin. Students have [studentId] populated;
/// guards and admins do not.
class AdminUser {
  final int id;
  final String fullName;
  final String email;

  /// null for GUARD and ADMIN roles.
  final String? studentId;

  /// 'STUDENT', 'GUARD', or 'ADMIN'.
  final String role;

  final bool isActive;
  final DateTime createdAt;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.studentId,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      studentId: json['studentId'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isStudent => role == 'STUDENT';
  bool get isGuard => role == 'GUARD';
  bool get isAdmin => role == 'ADMIN';
}
