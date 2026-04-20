// notification_screen.dart — S34: Notification list with mark-as-read and infinite scroll
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

/// S34 — Notifications screen.
///
/// Displays paginated notifications with:
/// - Optimistic mark-as-read on tap (blue dot fades out)
/// - "Mark all" button in header
/// - Infinite scroll via [NotificationProvider.loadMore]
/// - Shimmer loading, error + retry, and empty states
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () {
              final role = context.read<AuthProvider>().role;
              context.go(role == 'GUARD' ? '/guard/home' : '/student/home');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.arrowLeft,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Back',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          Text('Notifications', style: AppTypography.displaySmall),
          const Spacer(),

          // Mark all button
          Consumer<NotificationProvider>(
            builder: (_, provider, _) => GestureDetector(
              onTap: provider.isMarkingAll
                  ? null
                  : () => context.read<NotificationProvider>().markAllAsRead(),
              child: provider.isMarkingAll
                  ? const SizedBox(
                      width:  16,
                      height: 16,
                      child:  CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'Mark all',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return Consumer<NotificationProvider>(
      builder: (_, provider, _) {
        // Loading skeleton
        if (provider.isLoadingList && provider.notifications.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: List.generate(4, (_) => const _ShimmerCard()),
          );
        }

        // Error state
        if (provider.listError != null && provider.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.wifiOff,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text(provider.listError!, style: AppTypography.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.fetchNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (provider.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.bellOff,
                    size: 56, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No notifications yet',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        // Data list
        final notifications = provider.notifications;
        return ListView.builder(
          controller:  _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount:   notifications.length + (provider.hasMorePages ? 1 : 0),
          itemBuilder: (_, index) {
            if (index < notifications.length) {
              return _buildNotificationCard(notifications[index], provider);
            }
            // Load more spinner
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Notification card ─────────────────────────────────────────────────────────

  Widget _buildNotificationCard(
    AppNotification notification,
    NotificationProvider provider,
  ) {
    final typeColor = notification.typeColor;
    final icon      = _iconForType(notification.notificationType);

    return GestureDetector(
      onTap: () {
        provider.markAsRead(notification.id);
        if (notification.notificationType == 'CARPOOL_INVITE') {
          final badgeId = _extractBadgeId(notification.message);
          if (badgeId != null) {
            context.push('/student/badges/$badgeId/accept');
          } else {
            context.push('/student/badges');
          }
          return;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: notification.isUnread
              ? AppColors.surfaceHighlight
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon circle
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: typeColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTypography.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Unread indicator dot
            if (notification.isUnread)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(
                  width:  8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Extracts badge ID from a CARPOOL_INVITE notification message.
  /// Expected format: "...Badge ID: {id}, Badge Type: ..."
  int? _extractBadgeId(String message) {
    final match = RegExp(r'Badge ID:\s*(\d+)').firstMatch(message);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'RESERVATION_CONFIRMED': return LucideIcons.checkCircle;
      case 'FIVE_MIN_WARNING':      return LucideIcons.clock;
      case 'RESERVATION_EXPIRED':   return LucideIcons.xCircle;
      case 'POINTS_EARNED':         return LucideIcons.star;
      case 'SUSPENSION':            return LucideIcons.shieldAlert;
      case 'CARPOOL_INVITE':        return LucideIcons.userPlus;
      case 'SPOT_CONTRADICTION':    return LucideIcons.alertTriangle;
      default:                      return LucideIcons.bell;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff   = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer loading card
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:        AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ),
      ),
    );
  }
}
