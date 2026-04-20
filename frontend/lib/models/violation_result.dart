// violation_result.dart — Response from POST /guard/violations.

/// Result returned after a guard reports a parking violation.
/// Contains the new suspension details and affected badge members.
class ViolationResult {
  final int violationId;
  final int badgeId;
  final String badgeType;
  final int suspensionDays;
  final DateTime suspendedUntil;

  /// Full names of all badge members affected by this suspension.
  final List<String> affectedStudents;

  const ViolationResult({
    required this.violationId,
    required this.badgeId,
    required this.badgeType,
    required this.suspensionDays,
    required this.suspendedUntil,
    required this.affectedStudents,
  });

  factory ViolationResult.fromJson(Map<String, dynamic> json) {
    return ViolationResult(
      violationId: json['violationId'] as int,
      badgeId: json['badgeId'] as int,
      badgeType: json['badgeType'] as String,
      suspensionDays: json['suspensionDays'] as int,
      suspendedUntil: DateTime.parse(json['suspendedUntil'] as String),
      affectedStudents: (json['affectedStudents'] as List)
          .map((e) => e as String)
          .toList(),
    );
  }
}
