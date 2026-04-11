// spot.dart — Data model for a single parking spot with status colour helper
import 'package:flutter/material.dart';
import '../config/colors.dart';

/// Represents a single parking spot and its current occupancy status.
@immutable
class Spot {
  /// Database ID.
  final int id;

  /// Short zone identifier (e.g. 'A').
  final String zoneCode;

  /// Human-readable zone name (e.g. 'Main Parking').
  final String zoneName;

  /// Human-readable spot label (e.g. 'A3').
  final String spotLabel;

  /// Status string: 'AVAILABLE', 'RESERVED', 'OCCUPIED', or 'UNAVAILABLE'.
  final String status;

  /// When the status was last updated.
  final DateTime statusUpdatedAt;

  /// Creates a [Spot].
  const Spot({
    required this.id,
    required this.zoneCode,
    required this.zoneName,
    required this.spotLabel,
    required this.status,
    required this.statusUpdatedAt,
  });

  /// Deserialises from the backend JSON payload (camelCase keys).
  factory Spot.fromJson(Map<String, dynamic> json) => Spot(
        id: json['id'] as int,
        zoneCode: json['zoneCode'] as String,
        zoneName: json['zoneName'] as String,
        spotLabel: json['spotLabel'] as String,
        status: json['status'] as String,
        statusUpdatedAt: DateTime.parse(json['statusUpdatedAt'] as String),
      );

  /// Returns the colour that represents the current [status] on the map.
  Color get statusColor {
    switch (status) {
      case 'AVAILABLE':   return AppColors.available;
      case 'RESERVED':    return AppColors.reserved;
      case 'OCCUPIED':    return AppColors.occupied;
      default:            return AppColors.unavailable;
    }
  }

  bool get isAvailable   => status == 'AVAILABLE';
  bool get isReserved    => status == 'RESERVED';
  bool get isOccupied    => status == 'OCCUPIED';
  bool get isUnavailable => status == 'UNAVAILABLE';
}
