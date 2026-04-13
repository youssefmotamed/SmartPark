// scan_exit_response.dart — API response model for POST /gate/scan-exit
import 'package:flutter/foundation.dart';

/// Response from POST /gate/scan-exit.
///
/// Always HTTP 200 — check [exitRecorded] to determine scan outcome.
@immutable
class ScanExitResponse {
  final int?    reservationId;
  final String? spotLabel;
  final String? studentName;
  final int     pointsEarned;
  final bool    exitRecorded;

  const ScanExitResponse({
    required this.reservationId,
    required this.spotLabel,
    required this.studentName,
    required this.pointsEarned,
    required this.exitRecorded,
  });

  factory ScanExitResponse.fromJson(Map<String, dynamic> json) {
    return ScanExitResponse(
      reservationId: json['reservationId'] as int?,
      spotLabel:     json['spotLabel'] as String?,
      studentName:   json['studentName'] as String?,
      pointsEarned:  json['pointsEarned'] as int? ?? 0,
      exitRecorded:  json['exitRecorded'] as bool? ?? false,
    );
  }

  bool get isSuccess => exitRecorded;
}
