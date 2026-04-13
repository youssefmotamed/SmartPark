// scan_entry_response.dart — API response model for POST /gate/scan-entry
import 'package:flutter/foundation.dart';

/// Response from POST /gate/scan-entry.
///
/// Always HTTP 200 — check [valid] to determine scan outcome.
@immutable
class ScanEntryResponse {
  final bool         valid;
  final int?         reservationId;
  final String?      spotLabel;
  final String?      studentName;
  final String?      badgeType;
  final List<String> registeredPlates;
  final int?         timeRemainingSeconds;
  final String?      reason;

  const ScanEntryResponse({
    required this.valid,
    required this.reservationId,
    required this.spotLabel,
    required this.studentName,
    required this.badgeType,
    required this.registeredPlates,
    required this.timeRemainingSeconds,
    required this.reason,
  });

  factory ScanEntryResponse.fromJson(Map<String, dynamic> json) {
    return ScanEntryResponse(
      valid:                json['valid'] as bool? ?? false,
      reservationId:        json['reservationId'] as int?,
      spotLabel:            json['spotLabel'] as String?,
      studentName:          json['studentName'] as String?,
      badgeType:            json['badgeType'] as String?,
      registeredPlates:     json['registeredPlates'] != null
                                ? List<String>.from(json['registeredPlates'] as List<dynamic>)
                                : [],
      timeRemainingSeconds: json['timeRemainingSeconds'] as int?,
      reason:               json['reason'] as String?,
    );
  }

  bool   get isValid       => valid;
  String get displayReason => reason ?? 'Invalid QR code';
}
