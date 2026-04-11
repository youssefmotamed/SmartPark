// badge.dart — Data model for a SmartPark parking badge (individual or carpool)
import 'package:flutter/foundation.dart';

/// Represents a parking badge that owns reservations and accumulates points.
@immutable
class Badge {
  /// Database ID.
  final int id;

  /// Badge type string: 'INDIVIDUAL', 'CARPOOL_2' … 'CARPOOL_5'.
  final String badgeType;

  /// Unique alphanumeric badge code shown to the user.
  final String badgeCode;

  /// Current points balance for this badge.
  final int pointsBalance;

  /// Whether the badge is currently active.
  final bool isActive;

  /// If set, the badge is suspended until this timestamp.
  final DateTime? suspendedUntil;

  /// User ID of the badge owner.
  final int ownerId;

  /// Creates a [Badge].
  const Badge({
    required this.id,
    required this.badgeType,
    required this.badgeCode,
    required this.pointsBalance,
    required this.isActive,
    required this.ownerId,
    this.suspendedUntil,
  });

  /// Deserialises from the backend JSON payload.
  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
        id: json['id'] as int,
        badgeType: json['badge_type'] as String,
        badgeCode: json['badge_code'] as String,
        pointsBalance: json['points_balance'] as int,
        isActive: json['is_active'] as bool,
        suspendedUntil: json['suspended_until'] != null
            ? DateTime.parse(json['suspended_until'] as String)
            : null,
        ownerId: json['owner_id'] as int,
      );

  /// Returns true when the suspension window is active right now.
  bool get isSuspended =>
      suspendedUntil != null && suspendedUntil!.isAfter(DateTime.now());
}
