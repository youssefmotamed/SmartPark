// notification_page.dart — Paginated notification response wrapper
import 'app_notification.dart';

/// Wraps the paginated GET /notifications response.
class NotificationPage {
  final List<AppNotification> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

  const NotificationPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });

  /// True if there are more pages after this one.
  bool get hasMore => number < totalPages - 1;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    return NotificationPage(
      content: (json['content'] as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages:    json['totalPages']    as int? ?? 0,
      size:          json['size']          as int? ?? 20,
      number:        json['number']        as int? ?? 0,
    );
  }
}
