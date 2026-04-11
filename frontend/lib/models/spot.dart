// spot.dart — Data model for a single parking spot with status colour helper
import 'package:flutter/material.dart';
import '../config/colors.dart';

/// Represents a single parking spot and its current occupancy status.
@immutable
class Spot {
  /// Database ID.
  final int id;

  /// ID of the zone this spot belongs to.
  final int zoneId;

  /// Short zone identifier (e.g. 'A').
  final String zoneCode;

  /// Human-readable spot label (e.g. 'A3').
  final String spotLabel;

  /// Status string: 'AVAILABLE', 'RESERVED', 'OCCUPIED', or 'UNAVAILABLE'.
  final String status;

  /// When the status was last updated.
  final DateTime statusUpdatedAt;

  /// Creates a [Spot].
  const Spot({
    required this.id,
    required this.zoneId,
    required this.zoneCode,
    required this.spotLabel,
    required this.status,
    required this.statusUpdatedAt,
  });

  /// Deserialises from the backend JSON payload.
  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
        id: json['id'] as int,
        zoneId: json['zone_id'] as int,
        zoneCode: json['zone_code'] as String,
        spotLabel: json['spot_label'] as String,
        status: json['status'] as String,
        statusUpdatedAt:
            DateTime.parse(json['status_updated_at'] as String),
      );

  /// Returns the colour that represents the current [status] on the map.
  Color get statusColor {
    switch (status) {
      case 'AVAILABLE':
        return AppColors.available;
      case 'RESERVED':
        return AppColors.reserved;
      case 'OCCUPIED':
        return AppColors.occupied;
      default:
        return AppColors.unavailable;
    }
  }

  /// Convenience check: spot is free to reserve.
  bool get isAvailable => status == 'AVAILABLE';

  /// Convenience check: spot is reserved but not yet entered.
  bool get isReserved => status == 'RESERVED';

  /// Convenience check: a car is physically present.
  bool get isOccupied => status == 'OCCUPIED';

  /// Convenience check: spot is out of service.
  bool get isUnavailable => status == 'UNAVAILABLE';
}
