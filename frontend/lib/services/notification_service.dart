// notification_service.dart — Handles all notification API calls for SmartPark
import '../models/notification_page.dart';
import 'base_api_service.dart';

/// API service for GET /notifications, PATCH mark-as-read, and unread count.
class NotificationService extends BaseApiService {

  /// Fetches paginated notifications for the current user.
  /// Pass [unreadOnly] true to filter to unread notifications only.
  Future<NotificationPage> getNotifications({
    int  page       = 0,
    int  size       = 20,
    bool unreadOnly = false,
  }) async {
    final response = await get(
      '/notifications?page=$page&size=$size&unreadOnly=$unreadOnly',
    );
    return NotificationPage.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Returns the total count of unread notifications.
  /// Uses a size-1 query to read [totalElements] cheaply.
  Future<int> getUnreadCount() async {
    final page = await getNotifications(page: 0, size: 1, unreadOnly: true);
    return page.totalElements;
  }

  /// Marks a single notification as read.
  Future<void> markAsRead(int notificationId) async {
    await patch('/notifications/$notificationId/read');
  }

  /// Marks all notifications as read for the current user.
  Future<void> markAllAsRead() async {
    await patch('/notifications/read-all');
  }
}
