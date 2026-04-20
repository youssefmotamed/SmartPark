// admin_violation.dart — Violation record for GET /admin/violations.

/// One violation entry in the admin violations list.
class AdminViolation {
  final int violationId;
  final String plateNumber;

  /// 'NO_RESERVATION', 'WRONG_SPOT', 'UNAUTHORIZED', or 'IDLING'.
  final String violationType;

  final int suspensionDays;
  final String guardName;
  final int badgeId;
  final String badgeType;
  final DateTime createdAt;

  const AdminViolation({
    required this.violationId,
    required this.plateNumber,
    required this.violationType,
    required this.suspensionDays,
    required this.guardName,
    required this.badgeId,
    required this.badgeType,
    required this.createdAt,
  });

  factory AdminViolation.fromJson(Map<String, dynamic> json) {
    return AdminViolation(
      violationId: json['violationId'] as int,
      plateNumber: json['plateNumber'] as String,
      violationType: json['violationType'] as String,
      suspensionDays: json['suspensionDays'] as int,
      guardName: json['guardName'] as String,
      badgeId: json['badgeId'] as int,
      badgeType: json['badgeType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
