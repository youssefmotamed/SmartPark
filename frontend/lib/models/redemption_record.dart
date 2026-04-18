// redemption_record.dart — Model for each item in GET /rewards/redemptions list
import 'package:flutter/foundation.dart';

/// A record of a past reward redemption by the student.
/// Maps to each item in the `data` array of GET /rewards/redemptions.
@immutable
class RedemptionRecord {
  /// Database ID.
  final int id;

  /// Display name of the redeemed reward.
  final String rewardName;

  /// Machine-readable reward type, e.g. "ADVANCE_RESERVATION". Nullable for safety.
  final String? rewardType;

  /// Points that were deducted from the badge balance at redemption time.
  final int pointsDeducted;

  /// When the redemption was made.
  final DateTime redeemedAt;

  const RedemptionRecord({
    required this.id,
    required this.rewardName,
    this.rewardType,
    required this.pointsDeducted,
    required this.redeemedAt,
  });

  factory RedemptionRecord.fromJson(Map<String, dynamic> json) {
    return RedemptionRecord(
      id:             json['id']             as int,
      rewardName:     json['rewardName']     as String,
      rewardType:     json['rewardType']     as String?,
      pointsDeducted: json['pointsDeducted'] as int,
      redeemedAt:     DateTime.parse(json['redeemedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':             id,
    'rewardName':     rewardName,
    'rewardType':     rewardType,
    'pointsDeducted': pointsDeducted,
    'redeemedAt':     redeemedAt.toIso8601String(),
  };
}
