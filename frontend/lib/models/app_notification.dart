// app_notification.dart — Notification model matching the backend Phase 3 API response
// Named AppNotification to avoid collision with Flutter's Notification type.
import 'package:flutter/material.dart';
import '../config/colors.dart';

/// A single notification returned from GET /notifications.
/// Field names match the backend response exactly.
class AppNotification {
  final int      id;
  final String   notificationType;
  final String   title;
  final String   message;
  final DateTime createdAt;
  final bool     read;

  const AppNotification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
  });

  /// Returns true if this notification has not been read yet.
  bool get isUnread => !read;

  /// Returns the display color for this notification type.
  Color get typeColor {
    switch (notificationType) {
      case 'RESERVATION_EXPIRED':   return AppColors.error;
      case 'FIVE_MIN_WARNING':      return AppColors.warning;
      case 'SPOT_CONTRADICTION':    return AppColors.warning;
      case 'POINTS_EARNED':         return AppColors.primary;
      case 'SUSPENSION':            return AppColors.error;
      case 'CARPOOL_INVITE':        return AppColors.primary;
      case 'RESERVATION_CONFIRMED': return AppColors.success;
      default:                      return AppColors.textSecondary;
    }
  }

  /// Returns a human-readable label for this notification type.
  String get typeLabel {
    switch (notificationType) {
      case 'RESERVATION_EXPIRED':   return 'Expired';
      case 'FIVE_MIN_WARNING':      return 'Warning';
      case 'SPOT_CONTRADICTION':    return 'Alert';
      case 'POINTS_EARNED':         return 'Points';
      case 'SUSPENSION':            return 'Suspended';
      case 'CARPOOL_INVITE':        return 'Invite';
      case 'RESERVATION_CONFIRMED': return 'Confirmed';
      default:                      return 'Notification';
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:               json['id'] as int,
      notificationType: json['notificationType'] as String? ?? 'UNKNOWN',
      title:            json['title']   as String? ?? '',
      message:          json['message'] as String? ?? '',
      createdAt:        DateTime.parse(json['createdAt'] as String),
      read:             json['read']    as bool?   ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':               id,
    'notificationType': notificationType,
    'title':            title,
    'message':          message,
    'createdAt':        createdAt.toIso8601String(),
    'read':             read,
  };

  /// Returns a copy of this notification marked as read.
  AppNotification copyWithRead() => AppNotification(
    id:               id,
    notificationType: notificationType,
    title:            title,
    message:          message,
    createdAt:        createdAt,
    read:             true,
  );
}
