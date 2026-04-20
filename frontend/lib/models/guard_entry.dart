// guard_entry.dart — Represents one item in the combined guard/admin active
// entries list (GET /guard/reservations, GET /admin/reservations/active).
// A single list mixes RESERVATION and GUEST type entries.

/// One active parking entry — either a student reservation or a guard-created
/// guest parking slot. Check [isReservation] / [isGuest] before accessing
/// type-specific nullable fields.
class GuardEntry {
  /// 'RESERVATION' or 'GUEST'.
  final String type;
  final int id;
  final String spotLabel;
  final String zoneCode;

  // ── RESERVATION-only fields ──────────────────────────────────────────────
  final String? studentName;
  final String? badgeType;
  final String? status;
  final DateTime? reservedAt;
  final DateTime? expectedLeaveTime;
  final List<String>? plateNumbers;

  // ── GUEST-only fields ─────────────────────────────────────────────────────
  final String? guestPlateNumber;
  final String? purpose;
  final int? guardId;
  final DateTime? createdAt;

  const GuardEntry({
    required this.type,
    required this.id,
    required this.spotLabel,
    required this.zoneCode,
    this.studentName,
    this.badgeType,
    this.status,
    this.reservedAt,
    this.expectedLeaveTime,
    this.plateNumbers,
    this.guestPlateNumber,
    this.purpose,
    this.guardId,
    this.createdAt,
  });

  factory GuardEntry.fromJson(Map<String, dynamic> json) {
    return GuardEntry(
      type: json['type'] as String,
      id: json['id'] as int,
      spotLabel: json['spotLabel'] as String,
      zoneCode: json['zoneCode'] as String,
      studentName: json['studentName'] as String?,
      badgeType: json['badgeType'] as String?,
      status: json['status'] as String?,
      reservedAt: json['reservedAt'] != null
          ? DateTime.parse(json['reservedAt'] as String)
          : null,
      expectedLeaveTime: json['expectedLeaveTime'] != null
          ? DateTime.parse(json['expectedLeaveTime'] as String)
          : null,
      plateNumbers: (json['plateNumbers'] as List?)
          ?.map((e) => e as String)
          .toList(),
      guestPlateNumber: json['guestPlateNumber'] as String?,
      purpose: json['purpose'] as String?,
      guardId: json['guardId'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// True when this entry is a student reservation.
  bool get isReservation => type == 'RESERVATION';

  /// True when this entry is a guard-created guest parking slot.
  bool get isGuest => type == 'GUEST';
}
