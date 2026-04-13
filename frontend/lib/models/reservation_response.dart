// reservation_response.dart — API response model for a single reservation
import 'package:flutter/foundation.dart';

/// Represents a reservation as returned by the backend API.
///
/// Used for: POST /reservations, GET /reservations/active,
/// and items inside GET /reservations/history.
@immutable
class ReservationResponse {
  final int       id;
  final String    spotLabel;
  final String    zoneCode;
  final String    status;
  final String    qrCodeData;
  final DateTime  reservedAt;
  final DateTime? expiresAt;
  final DateTime  expectedLeaveTime;
  final String    badgeType;

  const ReservationResponse({
    required this.id,
    required this.spotLabel,
    required this.zoneCode,
    required this.status,
    required this.qrCodeData,
    required this.reservedAt,
    required this.expiresAt,
    required this.expectedLeaveTime,
    required this.badgeType,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
      id:                json['id'] as int,
      spotLabel:         json['spotLabel'] as String,
      zoneCode:          json['zoneCode'] as String,
      status:            json['status'] as String,
      qrCodeData:        json['qrCodeData'] as String? ?? '',
      reservedAt:        DateTime.parse(json['reservedAt'] as String),
      expiresAt:         json['expiresAt'] != null
                             ? DateTime.parse(json['expiresAt'] as String)
                             : null,
      expectedLeaveTime: DateTime.parse(json['expectedLeaveTime'] as String),
      badgeType:         json['badgeType'] as String? ?? 'INDIVIDUAL',
    );
  }

  Map<String, dynamic> toJson() => {
        'id':                id,
        'spotLabel':         spotLabel,
        'zoneCode':          zoneCode,
        'status':            status,
        'qrCodeData':        qrCodeData,
        'reservedAt':        reservedAt.toIso8601String(),
        'expiresAt':         expiresAt?.toIso8601String(),
        'expectedLeaveTime': expectedLeaveTime.toIso8601String(),
        'badgeType':         badgeType,
      };

  bool get isActive    => status == 'ACTIVE';
  bool get isEntered   => status == 'ENTERED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isExpired   => status == 'EXPIRED';
  bool get isCancelled => status == 'CANCELLED';

  /// Only ACTIVE reservations can be cancelled by the student.
  bool get canCancel => status == 'ACTIVE';

  /// Client-side expiry check — true when the timer has run out.
  bool get hasExpired =>
      expiresAt?.isBefore(DateTime.now()) ?? false;

  /// Time left before the reservation expires. Null once entry is scanned.
  Duration? get timeRemaining => expiresAt?.difference(DateTime.now());
}
