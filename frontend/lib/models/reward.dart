// reward.dart — Model for each item in GET /rewards list
import 'package:flutter/foundation.dart';

/// A redeemable reward available in the SmartPark rewards catalogue.
/// Maps to each item in the `data` array of GET /rewards.
@immutable
class Reward {
  /// Database ID — used when calling POST /rewards/{id}/redeem.
  final int id;

  /// Display name, e.g. "Advance Reservation".
  final String rewardName;

  /// Full description of what the reward grants.
  final String description;

  /// Points required to redeem this reward.
  final int pointsCost;

  /// Machine-readable type, e.g. "ADVANCE_RESERVATION".
  final String rewardType;

  /// Whether the reward is currently offered. False = greyed out in UI.
  final bool active;

  /// Whether the current student has enough points to afford this reward.
  /// Computed server-side against the active badge balance.
  final bool canAfford;

  const Reward({
    required this.id,
    required this.rewardName,
    required this.description,
    required this.pointsCost,
    required this.rewardType,
    required this.active,
    required this.canAfford,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id:          json['id']          as int,
      rewardName:  json['rewardName']  as String,
      description: json['description'] as String,
      pointsCost:  json['pointsCost']  as int,
      rewardType:  json['rewardType']  as String,
      active:      json['active']      as bool? ?? true,
      canAfford:   json['canAfford']   as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'rewardName':  rewardName,
    'description': description,
    'pointsCost':  pointsCost,
    'rewardType':  rewardType,
    'active':      active,
    'canAfford':   canAfford,
  };
}
