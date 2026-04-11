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
        id:             json['id'],
        badgeType:      json['badgeType'],
        badgeCode:      json['badgeCode']      ?? '',
        pointsBalance:  json['pointsBalance']  ?? 0,
        isActive:       json['isActive']       ?? true,
        suspendedUntil: json['suspendedUntil'] != null
            ? DateTime.parse(json['suspendedUntil'] as String)
            : null,
        ownerId: json['ownerId'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id':             id,
        'badgeType':      badgeType,
        'badgeCode':      badgeCode,
        'pointsBalance':  pointsBalance,
        'isActive':       isActive,
        'suspendedUntil': suspendedUntil?.toIso8601String(),
        'ownerId':        ownerId,
      };

  /// Returns true when the suspension window is active right now.
  bool get isSuspended =>
      suspendedUntil != null && suspendedUntil!.isAfter(DateTime.now());
}
