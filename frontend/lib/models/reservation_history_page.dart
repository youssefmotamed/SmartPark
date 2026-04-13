// reservation_history_page.dart — Paginated wrapper for GET /reservations/history
import 'package:flutter/foundation.dart';
import 'reservation_response.dart';

/// Wraps the paginated reservation history response.
@immutable
class ReservationHistoryPage {
  final List<ReservationResponse> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

  const ReservationHistoryPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });

  factory ReservationHistoryPage.fromJson(Map<String, dynamic> json) {
    return ReservationHistoryPage(
      content:       (json['content'] as List<dynamic>)
                         .map((e) => ReservationResponse.fromJson(e as Map<String, dynamic>))
                         .toList(),
      totalElements: json['totalElements'] as int,
      totalPages:    json['totalPages'] as int,
      size:          json['size'] as int,
      number:        json['number'] as int,
    );
  }

  /// True when there are more pages after the current one.
  bool get hasMore => number < totalPages - 1;
}
