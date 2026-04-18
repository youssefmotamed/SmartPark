// points_balance.dart — Model for GET /points/balance response
import 'package:flutter/foundation.dart';

/// Current points balance and badge info for the student's active badge.
/// Maps to the `data` field of GET /points/balance.
@immutable
class PointsBalance {
  /// The active badge ID.
  final int badgeId;

  /// Badge type string, e.g. "INDIVIDUAL", "CARPOOL_3".
  final String badgeType;

  /// Current spendable points balance.
  final int pointsBalance;

  /// Earnings multiplier based on badge type (1.0 for individual, up to 1.8 for carpool 5).
  final double multiplier;

  const PointsBalance({
    required this.badgeId,
    required this.badgeType,
    required this.pointsBalance,
    required this.multiplier,
  });

  factory PointsBalance.fromJson(Map<String, dynamic> json) {
    return PointsBalance(
      badgeId:       json['badgeId']       as int,
      badgeType:     json['badgeType']     as String,
      pointsBalance: json['pointsBalance'] as int,
      multiplier:    (json['multiplier'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'badgeId':       badgeId,
    'badgeType':     badgeType,
    'pointsBalance': pointsBalance,
    'multiplier':    multiplier,
  };
}
