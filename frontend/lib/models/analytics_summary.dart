// analytics_summary.dart — Response from GET /admin/analytics/summary.

/// Real-time campus parking and user statistics for the admin dashboard.
class AnalyticsSummary {
  final int totalSpots;
  final int occupiedSpots;
  final int reservedSpots;
  final int availableSpots;
  final int unavailableSpots;

  /// Percentage of spots currently occupied (0.0–100.0).
  final double occupancyRate;

  final int reservationsToday;
  final int violationsToday;
  final int activeBadges;
  final int suspendedBadges;
  final int totalStudents;
  final int totalGuards;

  const AnalyticsSummary({
    required this.totalSpots,
    required this.occupiedSpots,
    required this.reservedSpots,
    required this.availableSpots,
    required this.unavailableSpots,
    required this.occupancyRate,
    required this.reservationsToday,
    required this.violationsToday,
    required this.activeBadges,
    required this.suspendedBadges,
    required this.totalStudents,
    required this.totalGuards,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalSpots: json['totalSpots'] as int,
      occupiedSpots: json['occupiedSpots'] as int,
      reservedSpots: json['reservedSpots'] as int,
      availableSpots: json['availableSpots'] as int,
      unavailableSpots: json['unavailableSpots'] as int,
      occupancyRate: (json['occupancyRate'] as num).toDouble(),
      reservationsToday: json['reservationsToday'] as int,
      violationsToday: json['violationsToday'] as int,
      activeBadges: json['activeBadges'] as int,
      suspendedBadges: json['suspendedBadges'] as int,
      totalStudents: json['totalStudents'] as int,
      totalGuards: json['totalGuards'] as int,
    );
  }
}
