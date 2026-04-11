// zone.dart — Data model for a parking zone
import 'package:flutter/foundation.dart';

/// Represents a parking zone on campus (e.g. Zone A, B, C).
@immutable
class Zone {
  /// Database ID.
  final int id;

  /// Short zone identifier (e.g. 'A').
  final String zoneCode;

  /// Human-readable zone name (e.g. 'Main Parking').
  final String zoneName;

  /// Access type string: 'ALL', 'CARPOOL_ONLY', or 'GUARD_ONLY'.
  final String accessType;

  /// Creates a [Zone].
  const Zone({
    required this.id,
    required this.zoneCode,
    required this.zoneName,
    required this.accessType,
  });

  /// Deserialises from the backend JSON payload (camelCase keys).
  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id:         json['id'] as int,
        zoneCode:   json['zoneCode'] as String,
        zoneName:   json['zoneName'] as String,
        accessType: json['accessType'] as String,
      );

  bool get isCarPoolOnly => accessType == 'CARPOOL_ONLY';
  bool get isGuardOnly   => accessType == 'GUARD_ONLY';
}
