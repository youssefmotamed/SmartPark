// points_summary.dart — Model for GET /points/summary response
import 'package:flutter/foundation.dart';

/// Aggregate points statistics for the student's active badge.
/// Maps to the `data` field of GET /points/summary.
@immutable
class PointsSummary {
  /// Total points ever earned on this badge.
  final int totalEarned;

  /// Total points spent on rewards.
  final int totalSpent;

  /// Points that will expire within the next 30 days.
  final int expiringSoon;

  /// Current spendable balance (totalEarned - totalSpent - expired).
  final int currentBalance;

  const PointsSummary({
    required this.totalEarned,
    required this.totalSpent,
    required this.expiringSoon,
    required this.currentBalance,
  });

  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    return PointsSummary(
      totalEarned:    json['totalEarned']    as int,
      totalSpent:     json['totalSpent']     as int,
      expiringSoon:   json['expiringSoon']   as int,
      currentBalance: json['currentBalance'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalEarned':    totalEarned,
    'totalSpent':     totalSpent,
    'expiringSoon':   expiringSoon,
    'currentBalance': currentBalance,
  };
}
