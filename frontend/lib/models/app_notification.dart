// app_notification.dart — Data model for in-app notifications
// Named AppNotification to avoid collision with the Flutter/Dart Notification type.
import 'package:flutter/foundation.dart';

/// Represents an in-app notification sent to a user.
@immutable
class AppNotification {
  /// Database ID.
  final int id;

  /// ID of the user this notification belongs to.
  final int userId;

  /// Short notification title.
  final String title;

  /// Full notification body text.
  final String message;

  /// Type string matching the backend NotificationType enum
  /// (e.g. 'RESERVATION_CONFIRMED', 'FIVE_MIN_WARNING').
  final String type;

  /// Whether the user has already read this notification.
  final bool isRead;

  /// When the notification was created.
  final DateTime createdAt;

  /// Creates an [AppNotification].
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  /// Deserialises from the backend JSON payload.
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id:        json['id'],
        userId:    json['userId'],
        title:     json['title'],
        message:   json['message'],
        type:      json['type'],
        isRead:    json['isRead']    ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id':        id,
        'userId':    userId,
        'title':     title,
        'message':   message,
        'type':      type,
        'isRead':    isRead,
        'createdAt': createdAt.toIso8601String(),
      };
}
