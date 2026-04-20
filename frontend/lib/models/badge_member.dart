// badge_member.dart — One member slot inside a carpool badge
import 'package:flutter/foundation.dart';

/// Represents a single member entry inside a [BadgeDetail].
/// A slot may be unfilled (userId and name are null) or pending/accepted.
@immutable
class BadgeMember {
  /// The DB user ID of this member. Null if the slot is not yet filled.
  final int? userId;

  /// Display name of this member. Null if the slot is not yet filled.
  final String? name;

  /// Membership status: "ACCEPTED" or "PENDING".
  final String status;

  /// True if this member is the badge creator and can send invitations.
  final bool canInvite;

  const BadgeMember({
    this.userId,
    this.name,
    required this.status,
    required this.canInvite,
  });

  bool get isAccepted => status == 'ACCEPTED';
  bool get isPending  => status == 'PENDING';

  factory BadgeMember.fromJson(Map<String, dynamic> json) {
    return BadgeMember(
      userId:    json['userId']    as int?,
      name:      json['name']      as String?,
      status:    json['status']    as String,
      canInvite: json['canInvite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId':    userId,
    'name':      name,
    'status':    status,
    'canInvite': canInvite,
  };
}
