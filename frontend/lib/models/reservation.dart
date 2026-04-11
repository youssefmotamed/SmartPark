// reservation.dart — Data model for a parking reservation
import 'package:flutter/foundation.dart';

/// Represents a parking reservation made by a badge.
@immutable
class Reservation {
  /// Database ID.
  final int id;

  /// ID of the badge this reservation belongs to.
  final int badgeId;

  /// ID of the reserved spot.
  final int spotId;

  /// Human-readable spot label (e.g. 'A3').
  final String spotLabel;

  /// Zone code of the reserved spot.
  final String zoneCode;

  /// Status string: 'ACTIVE', 'ENTERED', 'COMPLETED', 'EXPIRED', 'CANCELLED'.
  final String status;

  /// When the reservation was created.
  final DateTime reservedAt;

  /// When the reservation expires (null after entry scan).
  final DateTime? expiresAt;

  /// When the entry QR was scanned; null before entry.
  final DateTime? enteredAt;

  /// When the exit QR was scanned; null before exit.
  final DateTime? exitedAt;

  /// QR code payload — contains only the reservation ID.
  final String? qrCode;

  /// Creates a [Reservation].
  const Reservation({
    required this.id,
    required this.badgeId,
    required this.spotId,
    required this.spotLabel,
    required this.zoneCode,
    required this.status,
    required this.reservedAt,
    this.expiresAt,
    this.enteredAt,
    this.exitedAt,
    this.qrCode,
  });

  /// Deserialises from the backend JSON payload.
  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as int,
        badgeId: json['badge_id'] as int,
        spotId: json['spot_id'] as int,
        spotLabel: json['spot_label'] as String,
        zoneCode: json['zone_code'] as String,
        status: json['status'] as String,
        reservedAt: DateTime.parse(json['reserved_at'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        enteredAt: json['entered_at'] != null
            ? DateTime.parse(json['entered_at'] as String)
            : null,
        exitedAt: json['exited_at'] != null
            ? DateTime.parse(json['exited_at'] as String)
            : null,
        qrCode: json['qr_code'] as String?,
      );

  /// Whether the student has scanned in at the gate.
  bool get hasEntered => enteredAt != null;

  /// Whether the reservation is still waiting for entry.
  bool get isActive => status == 'ACTIVE';

  /// Whether the student is currently parked.
  bool get isEntered => status == 'ENTERED';
}
