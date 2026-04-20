// badge_reservation.dart — Active reservation for a badge from GET /badges/{id}/reservation
import 'package:flutter/foundation.dart';

/// The active reservation associated with a badge.
/// Returned by GET /badges/{id}/reservation.
/// Returns 404 if no active reservation exists for the badge.
@immutable
class BadgeReservation {
  final int      reservationId;
  final String   spotLabel;
  final String   zoneCode;
  final String   status;
  final String   reservedByName;
  final DateTime reservedAt;
  final DateTime expectedLeaveTime;

  /// Null after the student has scanned into the gate.
  final DateTime? expiresAt;

  const BadgeReservation({
    required this.reservationId,
    required this.spotLabel,
    required this.zoneCode,
    required this.status,
    required this.reservedByName,
    required this.reservedAt,
    required this.expectedLeaveTime,
    this.expiresAt,
  });

  bool get hasExpiry => expiresAt != null;

  factory BadgeReservation.fromJson(Map<String, dynamic> json) {
    return BadgeReservation(
      reservationId:     json['reservationId']     as int,
      spotLabel:         json['spotLabel']         as String,
      zoneCode:          json['zoneCode']          as String,
      status:            json['status']            as String,
      reservedByName:    json['reservedByName']    as String,
      reservedAt:        DateTime.parse(json['reservedAt']         as String),
      expectedLeaveTime: DateTime.parse(json['expectedLeaveTime']  as String),
      expiresAt:         json['expiresAt'] != null
                             ? DateTime.parse(json['expiresAt'] as String)
                             : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'reservationId':     reservationId,
    'spotLabel':         spotLabel,
    'zoneCode':          zoneCode,
    'status':            status,
    'reservedByName':    reservedByName,
    'reservedAt':        reservedAt.toIso8601String(),
    'expectedLeaveTime': expectedLeaveTime.toIso8601String(),
    'expiresAt':         expiresAt?.toIso8601String(),
  };
}
