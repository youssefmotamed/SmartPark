// notification_bell.dart — Bell icon with animated unread badge for SmartPark
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../config/colors.dart';
import '../providers/notification_provider.dart';

/// Reusable bell icon that shows a red badge with the unread notification count.
///
/// Reads [NotificationProvider.unreadCount] directly — no props needed for count.
/// Shows "99+" when count exceeds 99. Badge animates in/out with elasticOut curve.
class NotificationBell extends StatelessWidget {
  /// Icon tint color. Defaults to [AppColors.textSecondary].
  final Color color;

  /// Called when the bell is tapped.
  final VoidCallback? onTap;

  const NotificationBell({
    super.key,
    this.color = AppColors.textSecondary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bell icon
          Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(LucideIcons.bell, size: 22, color: color),
          ),

          // Unread badge — only shown when count > 0
          if (unreadCount > 0)
            Positioned(
              top:   -2,
              right: -2,
              child: AnimatedScale(
                scale:    1.0,
                duration: const Duration(milliseconds: 200),
                curve:    Curves.elasticOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color:        AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.background, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      fontSize:   9,
                      fontWeight: FontWeight.w700,
                      color:      Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
