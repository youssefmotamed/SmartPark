// badge_summary.dart — Lightweight badge summary for GET /profile/badges list (S15)
import 'package:flutter/foundation.dart';

/// Lightweight member entry inside a [BadgeSummary].
///
/// Intentionally separate from [BadgeMember] (badge detail endpoint) because
/// the profile/badges endpoint does NOT return canInvite — only status.
@immutable
class BadgeSummaryMember {
  final int?   userId;
  final String? name;
  final String  status; // 'ACCEPTED' or 'PENDING'

  const BadgeSummaryMember({
    required this.userId,
    required this.name,
    required this.status,
  });

  factory BadgeSummaryMember.fromJson(Map<String, dynamic> json) {
    return BadgeSummaryMember(
      userId: json['userId'] as int?,
      name:   json['name']   as String?,
      status: json['status'] as String? ?? 'ACCEPTED',
    );
  }
}

/// Lightweight badge entry returned by GET /profile/badges.
///
/// Includes the full members list so S15 can detect whether the current user
/// is PENDING (invited but not yet accepted) and route to S20 instead of S16.
@immutable
class BadgeSummary {
  final int    badgeId;
  final String badgeType;
  final String status;
  final int    pointsBalance;
  final int    maxSlots;

  /// Number of cars registered to this badge (derived from cars list length).
  final int carCount;

  /// All member slots — used to check membership status per user.
  final List<BadgeSummaryMember> members;

  const BadgeSummary({
    required this.badgeId,
    required this.badgeType,
    required this.status,
    required this.pointsBalance,
    required this.maxSlots,
    required this.carCount,
    required this.members,
  });

  /// Total number of members (accepted + pending).
  int get memberCount => members.length;

  /// Only ACCEPTED members — excludes pending invitations.
  int get acceptedMemberCount =>
      members.where((m) => m.status == 'ACCEPTED').length;

  /// True if any member slot has PENDING status (open invitations exist).
  bool get hasPendingMembers =>
      members.any((m) => m.status == 'PENDING');

  bool get isActive    => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get isCarpool   => badgeType != 'INDIVIDUAL';

  /// Derives maximum slots from badge type — the profile/badges endpoint
  /// does not return maxSlots directly so we compute it from the type string.
  static int _maxSlotsFromType(String badgeType) {
    switch (badgeType) {
      case 'CARPOOL_2': return 2;
      case 'CARPOOL_3': return 3;
      case 'CARPOOL_4': return 4;
      case 'CARPOOL_5': return 5;
      default:          return 1; // INDIVIDUAL
    }
  }

  factory BadgeSummary.fromJson(Map<String, dynamic> json) {
    final badgeType   = json['badgeType'] as String;
    final membersList = (json['members'] as List? ?? [])
        .map((m) => BadgeSummaryMember.fromJson(m as Map<String, dynamic>))
        .toList();

    return BadgeSummary(
      badgeId:       json['badgeId']       as int,
      badgeType:     badgeType,
      status:        json['status']        as String,
      pointsBalance: json['pointsBalance'] as int,
      members:       membersList,
      maxSlots:      _maxSlotsFromType(badgeType),
      carCount:      (json['cars']         as List? ?? []).length,
    );
  }

  Map<String, dynamic> toJson() => {
    'badgeId':       badgeId,
    'badgeType':     badgeType,
    'status':        status,
    'pointsBalance': pointsBalance,
    'maxSlots':      maxSlots,
    'carCount':      carCount,
    'memberCount':   memberCount,
  };
}
