// zone.dart — Data model for a parking zone
import 'package:flutter/foundation.dart';

/// Represents a parking zone on campus (e.g. Zone A, B, C).
@immutable
class Zone {
  /// Database ID.
  final int id;

  /// Short zone identifier (e.g. 'A').
  final String zoneCode;

  /// Human-readable zone name (e.g. 'Zone A').
  final String zoneName;

  /// Access type string: 'ALL', 'CARPOOL_ONLY', or 'GUARD_ONLY'.
  final String accessType;

  /// Total number of spots in this zone.
  final int totalSpots;

  /// Creates a [Zone].
  const Zone({
    required this.id,
    required this.zoneCode,
    required this.zoneName,
    required this.accessType,
    required this.totalSpots,
  });

  /// Deserialises from the backend JSON payload.
  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
        id:         json['id'],
        zoneCode:   json['zoneCode'],
        zoneName:   json['zoneName'],
        accessType: json['accessType'],
        totalSpots: json['totalSpots'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id':         id,
        'zoneCode':   zoneCode,
        'zoneName':   zoneName,
        'accessType': accessType,
        'totalSpots': totalSpots,
      };
}
