// badge_management_screen.dart — S31: Admin badge list with suspend/unsuspend.
// Loads all badges with status filter, shows member names and stats per card.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/admin_badge.dart';
import '../../providers/admin_provider.dart';

/// S31 — Badge Management screen.
///
/// Lists all campus badges with status filter chips. Guards can be suspended
/// or unsuspended directly from each card.
class BadgeManagementScreen extends StatefulWidget {
  const BadgeManagementScreen({super.key});

  @override
  State<BadgeManagementScreen> createState() => _BadgeManagementScreenState();
}

class _BadgeManagementScreenState extends State<BadgeManagementScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus; // null = All

  static const _statusFilters = [
    (label: 'All',       value: null),
    (label: 'Active',    value: 'ACTIVE'),
    (label: 'Suspended', value: 'SUSPENDED'),
    (label: 'Expired',   value: 'EXPIRED'),
  ];

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadBadges();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminProvider>().loadMoreBadges();
    }
  }

  void _setStatus(String? status) {
    setState(() => _selectedStatus = status);
    context.read<AdminProvider>().loadBadges(status: status);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _badgeTierColor(String badgeType) {
    switch (badgeType) {
      case 'CARPOOL_2': return AppColors.carpool2;
      case 'CARPOOL_3': return AppColors.carpool3;
      case 'CARPOOL_4': return AppColors.carpool4;
      case 'CARPOOL_5': return AppColors.carpool5;
      default:          return AppColors.individual;
    }
  }

  String _formatBadgeType(String badgeType) {
    switch (badgeType) {
      case 'INDIVIDUAL': return 'Individual';
      case 'CARPOOL_2':  return 'Carpool 2';
      case 'CARPOOL_3':  return 'Carpool 3';
      case 'CARPOOL_4':  return 'Carpool 4';
      case 'CARPOOL_5':  return 'Carpool 5';
      default:           return badgeType;
    }
  }

  String _formatMonthYear(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.year}';

  String _formatDateTime(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleSuspend(
      int badgeId, int days, String reason) async {
    final success = await context.read<AdminProvider>().suspendBadge(
      badgeId,
      suspensionDays: days,
      reason:         reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Badge suspended for $days day(s)'
          : context.read<AdminProvider>().operationError ?? 'Failed'),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _handleUnsuspend(int badgeId) async {
    final success = await context.read<AdminProvider>().unsuspendBadge(badgeId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? 'Badge unsuspended'
          : context.read<AdminProvider>().operationError ?? 'Failed'),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuspendDialog(AdminBadge badge) {
    int    suspensionDays   = 1;
    final  reasonController = TextEditingController();

    showModalBottomSheet<void>(
      context:            context,
      backgroundColor:    AppColors.surfaceLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left:   20,
            right:  20,
            top:    16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize:      MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width:  40,
                  height: 4,
                  decoration: BoxDecoration(
                    color:        AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Suspend Badge', style: AppTypography.displaySmall),
              Text(
                'Badge #${badge.badgeId} — ${_formatBadgeType(badge.badgeType)}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              Text('Suspension Duration',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [1, 3, 7, 14, 30].map((days) {
                  final selected = suspensionDays == days;
                  return GestureDetector(
                    onTap: () => setSheetState(() => suspensionDays = days),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.surfaceHighlight,
                        border: Border.all(
                          color: selected ? AppColors.error : AppColors.divider,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${days}d',
                        style: AppTypography.labelMedium.copyWith(
                          color: selected
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Text('Reason',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines:   2,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText:  'Reason for suspension...',
                  hintStyle: AppTypography.bodyMedium,
                  filled:    true,
                  fillColor: AppColors.surfaceHighlight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:   BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.buttonRadius)),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final reason = reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : 'Admin suspension';
                    reasonController.dispose();
                    await _handleSuspend(badge.badgeId, suspensionDays, reason);
                  },
                  child: Text(
                    'Suspend for $suspensionDays day(s)',
                    style: AppTypography.labelLarge
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Badge Management', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          // ── Filter chips ─────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: _statusFilters.length,
              itemBuilder: (_, i) {
                final f          = _statusFilters[i];
                final isSelected = _selectedStatus == f.value;
                return GestureDetector(
                  onTap: () => _setStatus(f.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      f.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: () {
              if (provider.isLoadingBadges && provider.badges.isEmpty) {
                return _buildLoading();
              }
              if (provider.badgesError != null && provider.badges.isEmpty) {
                return _buildError(provider);
              }
              if (provider.badges.isEmpty) {
                return _buildEmpty();
              }
              return _buildList(provider);
            }(),
          ),
        ],
      ),
    );
  }

  // ── Badge list ─────────────────────────────────────────────────────────────

  Widget _buildList(AdminProvider provider) {
    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>()
          .loadBadges(status: _selectedStatus),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount:
            provider.badges.length + (provider.badgesHasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == provider.badges.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            );
          }
          return _BadgeCard(
            badge:          provider.badges[i],
            tierColor:      _badgeTierColor(provider.badges[i].badgeType),
            formatBadgeType: _formatBadgeType,
            formatMonthYear: _formatMonthYear,
            formatDate:      _formatDateTime,
            onSuspend:  () => _showSuspendDialog(provider.badges[i]),
            onUnsuspend: () =>
                _handleUnsuspend(provider.badges[i].badgeId),
            onViewMembers: () => context.push(
                '/admin/badges/${provider.badges[i].badgeId}/members'),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: 5,
      itemBuilder: (_, _) => Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.creditCard,
              size: 48, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text('No badges found'),
        ],
      ),
    );
  }

  Widget _buildError(AdminProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(provider.badgesError!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AdminProvider>()
                  .loadBadges(status: _selectedStatus),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius)),
              ),
              child: Text('Retry',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.background)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge card
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final AdminBadge   badge;
  final Color        tierColor;
  final String Function(String) formatBadgeType;
  final String Function(DateTime) formatMonthYear;
  final String Function(DateTime) formatDate;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;
  final VoidCallback onViewMembers;

  const _BadgeCard({
    required this.badge,
    required this.tierColor,
    required this.formatBadgeType,
    required this.formatMonthYear,
    required this.formatDate,
    required this.onSuspend,
    required this.onUnsuspend,
    required this.onViewMembers,
  });

  @override
  Widget build(BuildContext context) {
    final memberNames = badge.members
        .where((m) => m.status == 'ACCEPTED')
        .map((m) => m.name)
        .toList();
    final displayedNames = memberNames.take(2).join(', ');
    final extraCount     = memberNames.length > 2
        ? memberNames.length - 2
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent
            Container(width: 4, color: tierColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: type + status
                    Row(
                      children: [
                        Text(
                          formatBadgeType(badge.badgeType),
                          style: AppTypography.labelMedium
                              .copyWith(color: tierColor),
                        ),
                        const Spacer(),
                        _StatusPill(status: badge.status),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Members row
                    Row(
                      children: [
                        const Icon(LucideIcons.users,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            memberNames.isEmpty
                                ? 'No members'
                                : extraCount > 0
                                    ? '$displayedNames  +$extraCount more'
                                    : displayedNames,
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Stats row
                    Row(
                      children: [
                        const Icon(LucideIcons.star,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text('${badge.pointsBalance} pts',
                            style: AppTypography.bodySmall),
                        Text('  ·  ',
                            style: AppTypography.bodySmall),
                        Icon(LucideIcons.alertTriangle,
                            size: 12,
                            color: badge.violationCount > 0
                                ? AppColors.error
                                : AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          '${badge.violationCount} violations',
                          style: AppTypography.bodySmall.copyWith(
                            color: badge.violationCount > 0
                                ? AppColors.error
                                : AppColors.textTertiary,
                          ),
                        ),
                        Text('  ·  ',
                            style: AppTypography.bodySmall),
                        Text(
                          'Expires ${formatMonthYear(badge.expiresAt)}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),

                    // Suspension info
                    if (badge.status == 'SUSPENDED' &&
                        badge.suspendedUntil != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color:        AppColors.error.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.clock,
                                size: 12, color: AppColors.error),
                            const SizedBox(width: 5),
                            Text(
                              'Suspended until ${formatDate(badge.suspendedUntil!)}',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Action buttons
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (badge.status == 'ACTIVE')
                          TextButton(
                            onPressed: onSuspend,
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8)),
                            child: Text('Suspend',
                                style: AppTypography.labelSmall
                                    .copyWith(color: AppColors.error)),
                          ),
                        if (badge.status == 'SUSPENDED')
                          TextButton(
                            onPressed: onUnsuspend,
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8)),
                            child: Text('Unsuspend',
                                style: AppTypography.labelSmall
                                    .copyWith(color: AppColors.success)),
                          ),
                        TextButton(
                          onPressed: onViewMembers,
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8)),
                          child: Text('View Members',
                              style: AppTypography.labelSmall
                                  .copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'ACTIVE'    => (AppColors.success,      'Active'),
      'SUSPENDED' => (AppColors.error,        'Suspended'),
      _           => (AppColors.textTertiary, 'Expired'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall
            .copyWith(color: color, fontSize: 10),
      ),
    );
  }
}
