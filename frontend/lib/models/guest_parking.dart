// guest_parking.dart — Response model for POST /guard/guest-parking and
// PATCH /guard/guest-parking/{id}/complete.

/// Represents a guard-created guest parking slot in Zone C.
class GuestParking {
  final int id;
  final int spotId;
  final String spotLabel;
  final String zoneCode;
  final String guestPlateNumber;
  final String? purpose;

  /// 'ACTIVE' or 'COMPLETED'.
  final String status;

  final int guardId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const GuestParking({
    required this.id,
    required this.spotId,
    required this.spotLabel,
    required this.zoneCode,
    required this.guestPlateNumber,
    this.purpose,
    required this.status,
    required this.guardId,
    required this.createdAt,
    this.completedAt,
  });

  factory GuestParking.fromJson(Map<String, dynamic> json) {
    return GuestParking(
      id: json['id'] as int,
      spotId: json['spotId'] as int,
      spotLabel: json['spotLabel'] as String,
      zoneCode: json['zoneCode'] as String,
      guestPlateNumber: json['guestPlateNumber'] as String,
      purpose: json['purpose'] as String?,
      status: json['status'] as String,
      guardId: json['guardId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  bool get isActive => status == 'ACTIVE';
  bool get isCompleted => status == 'COMPLETED';
}
