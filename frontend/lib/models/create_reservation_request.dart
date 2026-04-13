// create_reservation_request.dart — Request body for POST /reservations
import 'package:flutter/foundation.dart';

/// Request model for creating a reservation.
///
/// Serialises to the body of POST /reservations.
/// No fromJson — this is outbound only.
@immutable
class CreateReservationRequest {
  final int     spotId;
  final int     badgeId;
  final DateTime expectedLeaveTime;
  final double? latitude;
  final double? longitude;

  const CreateReservationRequest({
    required this.spotId,
    required this.badgeId,
    required this.expectedLeaveTime,
    this.latitude,
    this.longitude,
  });

  /// Serialises to JSON for the request body.
  ///
  /// [expectedLeaveTime] is trimmed to seconds — Youssef's API expects
  /// "2026-12-20T16:00:00" without milliseconds.
  Map<String, dynamic> toJson() => {
        'spotId':            spotId,
        'badgeId':           badgeId,
        'expectedLeaveTime': expectedLeaveTime.toIso8601String().split('.')[0],
        'latitude':          latitude,
        'longitude':         longitude,
      };
}
