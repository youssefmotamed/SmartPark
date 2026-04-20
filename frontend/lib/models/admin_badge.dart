// admin_badge.dart — Badge model for GET /admin/badges and related admin
// badge management endpoints. Includes the nested [AdminBadgeMember] class.

/// A badge member as seen in the admin badge detail.
class AdminBadgeMember {
  final int userId;
  final String name;

  /// null for non-student members (should not occur in practice).
  final String? studentId;

  /// 'PENDING' or 'ACCEPTED'.
  final String status;

  const AdminBadgeMember({
    required this.userId,
    required this.name,
    this.studentId,
    required this.status,
  });

  factory AdminBadgeMember.fromJson(Map<String, dynamic> json) {
    return AdminBadgeMember(
      userId: json['userId'] as int,
      name: json['name'] as String,
      studentId: json['studentId'] as String?,
      status: json['status'] as String,
    );
  }
}

/// Full badge record as seen by an admin. Includes all members.
class AdminBadge {
  final int badgeId;
  final String badgeType;
  final String status;
  final int pointsBalance;
  final int maxSlots;
  final int violationCount;
  final DateTime? suspendedUntil;
  final String? suspensionReason;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<AdminBadgeMember> members;

  const AdminBadge({
    required this.badgeId,
    required this.badgeType,
    required this.status,
    required this.pointsBalance,
    required this.maxSlots,
    required this.violationCount,
    this.suspendedUntil,
    this.suspensionReason,
    required this.createdAt,
    required this.expiresAt,
    required this.members,
  });

  factory AdminBadge.fromJson(Map<String, dynamic> json) {
    return AdminBadge(
      badgeId: json['badgeId'] as int,
      badgeType: json['badgeType'] as String,
      status: json['status'] as String,
      pointsBalance: json['pointsBalance'] as int,
      maxSlots: json['maxSlots'] as int,
      violationCount: json['violationCount'] as int,
      suspendedUntil: json['suspendedUntil'] != null
          ? DateTime.parse(json['suspendedUntil'] as String)
          : null,
      suspensionReason: json['suspensionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      members: (json['members'] as List)
          .map((e) => AdminBadgeMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isSuspended => status == 'SUSPENDED';
  bool get isActive => status == 'ACTIVE';
}
