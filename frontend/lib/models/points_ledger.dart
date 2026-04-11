// points_ledger.dart — Data model for a single points transaction entry
import 'package:flutter/foundation.dart';

/// Represents one entry in a badge's points history ledger.
@immutable
class PointsLedger {
  /// Database ID.
  final int id;

  /// ID of the badge this entry belongs to.
  final int badgeId;

  /// Points amount (positive = earned, negative = spent).
  final int points;

  /// Human-readable reason for the transaction.
  final String reason;

  /// When the points were recorded.
  final DateTime earnedAt;

  /// When the points expire; null if they do not expire.
  final DateTime? expiresAt;

  /// Creates a [PointsLedger] entry.
  const PointsLedger({
    required this.id,
    required this.badgeId,
    required this.points,
    required this.reason,
    required this.earnedAt,
    this.expiresAt,
  });

  /// Deserialises from the backend JSON payload.
  factory PointsLedger.fromJson(Map<String, dynamic> json) => PointsLedger(
        id: json['id'] as int,
        badgeId: json['badge_id'] as int,
        points: json['points'] as int,
        reason: json['reason'] as String,
        earnedAt: DateTime.parse(json['earned_at'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
      );
}
