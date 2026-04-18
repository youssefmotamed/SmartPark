// badge_summary.dart — Lightweight badge summary for GET /profile/badges list (S15)
import 'package:flutter/foundation.dart';

/// Lightweight badge entry returned by GET /profile/badges.
///
/// Uses a dual-key fromJson to handle both camelCase and snake_case responses
/// from the backend, since the key format for this endpoint is uncertain.
@immutable
class BadgeSummary {
  final int    badgeId;
  final String badgeType;
  final String status;
  final int    pointsBalance;

  /// Number of accepted members (derived from the members list length).
  final int memberCount;

  /// Maximum slots for this badge type (1 for INDIVIDUAL, 2–5 for CARPOOL_N).
  final int maxSlots;

  const BadgeSummary({
    required this.badgeId,
    required this.badgeType,
    required this.status,
    required this.pointsBalance,
    required this.memberCount,
    required this.maxSlots,
  });

  bool get isActive    => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get isCarpool   => badgeType != 'INDIVIDUAL';

  factory BadgeSummary.fromJson(Map<String, dynamic> json) {
    return BadgeSummary(
      badgeId:       (json['badgeId']       ?? json['badge_id'])       as int,
      badgeType:     (json['badgeType']      ?? json['badge_type'])     as String,
      status:        json['status']                                     as String,
      pointsBalance: (json['pointsBalance']  ?? json['points_balance']) as int,
      memberCount:   (json['members'] as List?)?.length ?? 1,
      maxSlots:      (json['maxSlots']       ?? json['max_slots']       ?? 1) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'badgeId':       badgeId,
    'badgeType':     badgeType,
    'status':        status,
    'pointsBalance': pointsBalance,
    'memberCount':   memberCount,
    'maxSlots':      maxSlots,
  };
}
