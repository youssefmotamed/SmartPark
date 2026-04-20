// badge_detail.dart — Full badge detail from GET /badges/{id} and badge mutation endpoints
import 'package:flutter/foundation.dart';
import 'badge_member.dart';
import 'badge_car.dart';

/// Full badge detail including members, cars, and slot info.
///
/// Returned by GET /badges/{id}, POST /badges, POST /badges/{id}/invite,
/// POST /badges/{id}/add-car, and POST /badges/{id}/accept.
@immutable
class BadgeDetail {
  final int            badgeId;
  final String         badgeType;
  final String         status;
  final int            pointsBalance;
  final int            maxSlots;
  final int            violationCount;
  final DateTime       createdAt;
  final DateTime       expiresAt;
  final List<BadgeMember> members;
  final List<BadgeCar>    cars;

  const BadgeDetail({
    required this.badgeId,
    required this.badgeType,
    required this.status,
    required this.pointsBalance,
    required this.maxSlots,
    required this.violationCount,
    required this.createdAt,
    required this.expiresAt,
    required this.members,
    required this.cars,
  });

  /// How many car slots are still unfilled.
  int get slotsRemaining => maxSlots - cars.length;

  /// Cars belonging to ACCEPTED members only.
  /// Matches car ownerName against ACCEPTED member names.
  List<BadgeCar> get acceptedMemberCars {
    final acceptedNames = members
        .where((m) => m.status == 'ACCEPTED' && m.name != null)
        .map((m) => m.name!)
        .toSet();
    return cars.where((c) => acceptedNames.contains(c.ownerName)).toList();
  }

  /// Number of members who have ACCEPTED (excludes PENDING invitations).
  int get acceptedMemberCount =>
      members.where((m) => m.status == 'ACCEPTED').length;

  /// Number of members with PENDING status (invited but not yet accepted).
  int get pendingMemberCount =>
      members.where((m) => m.status == 'PENDING').length;

  /// Whether this is a carpool badge (not individual).
  bool get isCarpool => badgeType != 'INDIVIDUAL';

  /// The member with creator privileges (canInvite == true), or null.
  BadgeMember? get creator =>
      members.where((m) => m.canInvite).firstOrNull;

  bool get isActive    => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';

  factory BadgeDetail.fromJson(Map<String, dynamic> json) {
    final membersList = (json['members'] as List<dynamic>? ?? [])
        .map((e) => BadgeMember.fromJson(e as Map<String, dynamic>))
        .toList();
    final carsList = (json['cars'] as List<dynamic>? ?? [])
        .map((e) => BadgeCar.fromJson(e as Map<String, dynamic>))
        .toList();

    return BadgeDetail(
      badgeId:        json['badgeId']        as int,
      badgeType:      json['badgeType']      as String,
      status:         json['status']         as String,
      pointsBalance:  json['pointsBalance']  as int,
      maxSlots:       json['maxSlots']       as int,
      violationCount: json['violationCount'] as int,
      createdAt:      DateTime.parse(json['createdAt']  as String),
      expiresAt:      DateTime.parse(json['expiresAt']  as String),
      members:        membersList,
      cars:           carsList,
    );
  }

  Map<String, dynamic> toJson() => {
    'badgeId':        badgeId,
    'badgeType':      badgeType,
    'status':         status,
    'pointsBalance':  pointsBalance,
    'maxSlots':       maxSlots,
    'violationCount': violationCount,
    'createdAt':      createdAt.toIso8601String(),
    'expiresAt':      expiresAt.toIso8601String(),
    'members':        members.map((m) => m.toJson()).toList(),
    'cars':           cars.map((c) => c.toJson()).toList(),
  };
}
