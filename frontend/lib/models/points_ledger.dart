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
        id:        json['id'],
        badgeId:   json['badgeId'],
        points:    json['points'],
        reason:    json['reason'],
        earnedAt:  DateTime.parse(json['earnedAt'] as String),
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id':        id,
        'badgeId':   badgeId,
        'points':    points,
        'reason':    reason,
        'earnedAt':  earnedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };
}
