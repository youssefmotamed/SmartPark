// points_transaction.dart — Model for a single entry in GET /points/history
import 'package:flutter/foundation.dart';

/// A single points ledger transaction returned in the paginated history list.
/// Maps to each item in the `content` array of GET /points/history.
@immutable
class PointsTransaction {
  /// Database ID.
  final int id;

  /// Points amount. May be negative for SPENT entries — use [absPoints] for display.
  final int points;

  /// Transaction type: EARNED, SPENT, DIVIDED, POOLED, or EXPIRED.
  final String transactionType;

  /// Human-readable description of the transaction.
  final String description;

  /// When the transaction was recorded.
  final DateTime createdAt;

  /// When these points expire. Null if they do not expire or have no expiry.
  final DateTime? expiresAt;

  const PointsTransaction({
    required this.id,
    required this.points,
    required this.transactionType,
    required this.description,
    required this.createdAt,
    this.expiresAt,
  });

  /// Absolute value of [points] — use this for display to avoid showing negatives.
  int get absPoints => points.abs();

  /// True when this transaction reduced the balance.
  bool get isDebit => transactionType == 'SPENT' || transactionType == 'EXPIRED';

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id:              json['id']              as int,
      points:          json['points']          as int,
      transactionType: json['transactionType'] as String,
      description:     json['description']     as String,
      createdAt:       DateTime.parse(json['createdAt'] as String),
      expiresAt:       json['expiresAt'] != null
                           ? DateTime.parse(json['expiresAt'] as String)
                           : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'points':          points,
    'transactionType': transactionType,
    'description':     description,
    'createdAt':       createdAt.toIso8601String(),
    'expiresAt':       expiresAt?.toIso8601String(),
  };
}
