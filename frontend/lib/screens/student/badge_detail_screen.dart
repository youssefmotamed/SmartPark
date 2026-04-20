// badge_detail_screen.dart — S16: Full badge detail with members, cars, and reservation
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/badge_detail.dart';
import '../../models/badge_member.dart';
import '../../models/badge_reservation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';

/// S16 — Badge Detail screen.
///
/// Shows full badge info: status header, active reservation, member list, and
/// registered cars. Creators see invite and add-car actions.
class BadgeDetailScreen extends StatefulWidget {
  final int badgeId;
  const BadgeDetailScreen({super.key, required this.badgeId});

  @override
  State<BadgeDetailScreen> createState() => _BadgeDetailScreenState();
}

class _BadgeDetailScreenState extends State<BadgeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double>   _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BadgeProvider>().loadBadgeDetail(widget.badgeId);
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _tierColor(String badgeType) {
    switch (badgeType) {
      case 'CARPOOL_2': return AppColors.carpool2;
      case 'CARPOOL_3': return AppColors.carpool3;
      case 'CARPOOL_4': return AppColors.carpool4;
      case 'CARPOOL_5': return AppColors.carpool5;
      default:          return AppColors.individual;
    }
  }

  String _badgeLabel(String badgeType) {
    if (badgeType == 'INDIVIDUAL') return 'Individual';
    final parts = badgeType.split('_');
    if (parts.length == 2) {
      final word = parts[0][0] + parts[0].substring(1).toLowerCase();
      return '$word ${parts[1]}';
    }
    return badgeType;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _isCreator(BadgeDetail badge, int? userId) {
    if (userId == null) return false;
    return badge.members.any((m) => m.canInvite && m.userId == userId);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<BadgeProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final badge       = provider.selectedBadge;

    final title = badge != null ? _badgeLabel(badge.badgeType) : 'Badge Detail';

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
        title: Text(title, style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: _buildBody(provider, badge, currentUser?.id),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BadgeProvider provider, BadgeDetail? badge, int? userId) {
    if (provider.isLoadingDetail && badge == null) {
      return _buildShimmer();
    }

    if (provider.detailError != null && badge == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.detailError!,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context
                  .read<BadgeProvider>()
                  .loadBadgeDetail(widget.badgeId),
              child: Text('Retry',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (badge == null) return const SizedBox.shrink();

    final isCreator = _isCreator(badge, userId);
    final tierColor  = _tierColor(badge.badgeType);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => context
          .read<BadgeProvider>()
          .loadBadgeDetail(widget.badgeId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(badge, tierColor),
            const SizedBox(height: 20),
            _buildReservationSection(
                context.watch<BadgeProvider>()),
            const SizedBox(height: 20),
            _buildMembersSection(badge, tierColor, isCreator),
            const SizedBox(height: 20),
            _buildCarsSection(badge, isCreator),
            if (badge.isActive && isCreator &&
                badge.slotsRemaining > 0) ...[
              const SizedBox(height: 24),
              _buildActionButton(badge),
            ],
          ],
        ),
      ),
    );
  }

  // ── Status card ───────────────────────────────────────────────────────────

  Widget _buildStatusCard(BadgeDetail badge, Color tierColor) {
    Color statusColor() {
      switch (badge.status) {
        case 'ACTIVE':    return AppColors.success;
        case 'SUSPENDED': return AppColors.error;
        default:          return AppColors.textTertiary;
      }
    }

    final sc = statusColor();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.25), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _badgeLabel(badge.badgeType),
                  style: AppTypography.displaySmall
                      .copyWith(color: tierColor),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.status,
                    style: AppTypography.labelSmall
                        .copyWith(color: sc, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Right column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${badge.pointsBalance}',
                style: AppTypography.displaySmall
                    .copyWith(color: AppColors.primary),
              ),
              Text(
                'points',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (badge.isCarpool) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (badge.slotsRemaining > 0
                            ? AppColors.warning
                            : AppColors.textTertiary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${badge.slotsRemaining} slots open',
                    style: AppTypography.labelSmall.copyWith(
                      color: badge.slotsRemaining > 0
                          ? AppColors.warning
                          : AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Reservation section ───────────────────────────────────────────────────

  Widget _buildReservationSection(BadgeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Reservation',
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        if (provider.isLoadingReservation)
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          )
        else if (provider.hasNoReservation ||
            provider.badgeReservation == null)
          Opacity(
            opacity: 0.5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.parkingSquare,
                      size: 32, color: AppColors.textTertiary),
                  const SizedBox(width: 12),
                  Text('No active reservation',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
          )
        else
          _buildReservationCard(provider.badgeReservation!),
      ],
    );
  }

  Widget _buildReservationCard(BadgeReservation res) {
    final isEntered   = res.status == 'ENTERED';
    final accentColor = isEntered ? AppColors.success : AppColors.reserved;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spot + zone
                    Row(
                      children: [
                        Text(
                          'Spot ${res.spotLabel}',
                          style: AppTypography.displaySmall
                              .copyWith(color: AppColors.primary),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Zone ${res.zoneCode}',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reserved by ${res.reservedByName}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(LucideIcons.clock,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Leave by ${_formatTime(res.expectedLeaveTime)}',
                          style: AppTypography.bodySmall,
                        ),
                        const Spacer(),
                        if (isEntered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'On campus',
                              style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.success, fontSize: 11),
                            ),
                          )
                        else if (res.expiresAt != null)
                          Text(
                            _expiresIn(res.expiresAt!),
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.warning),
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

  String _expiresIn(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    final mins = diff.inMinutes;
    return 'Expires in $mins min';
  }

  // ── Members section ───────────────────────────────────────────────────────

  Widget _buildMembersSection(
      BadgeDetail badge, Color tierColor, bool isCreator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Members (${badge.acceptedMemberCount}/${badge.maxSlots})',
          style: AppTypography.labelMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Filled member rows
              ...badge.members.asMap().entries.map((entry) {
                final i      = entry.key;
                final member = entry.value;
                return Column(
                  children: [
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.divider,
                          indent: 16, endIndent: 16),
                    _buildMemberRow(member, tierColor),
                  ],
                );
              }),

              // Empty slot rows
              if (badge.isCarpool)
                ...List.generate(badge.slotsRemaining, (i) {
                  final showDivider =
                      badge.members.isNotEmpty || i > 0;
                  return Column(
                    children: [
                      if (showDivider)
                        const Divider(height: 1, color: AppColors.divider,
                            indent: 16, endIndent: 16),
                      _buildEmptySlotRow(isCreator),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberRow(BadgeMember member, Color tierColor) {
    final hasName    = member.name != null && member.name!.isNotEmpty;
    final initial    = hasName ? member.name![0].toUpperCase() : null;
    final isAccepted = member.isAccepted;
    final statusColor = isAccepted ? AppColors.success : AppColors.warning;
    final statusLabel = isAccepted ? 'Active' : 'Pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: initial != null
                  ? Text(initial,
                      style: AppTypography.labelMedium.copyWith(color: tierColor))
                  : Icon(LucideIcons.user, size: 18, color: tierColor),
            ),
          ),
          const SizedBox(width: 12),

          // Name + creator badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? member.name! : 'Unknown',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
                if (member.canInvite)
                  Text('Creator',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.primary, fontSize: 11)),
              ],
            ),
          ),

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusLabel,
              style: AppTypography.labelSmall
                  .copyWith(color: statusColor, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotRow(bool isCreator) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(LucideIcons.userPlus,
                  size: 18, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Open slot',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textTertiary)),
          ),
          if (isCreator)
            TextButton(
              onPressed: () => context.push(
                  '/student/badges/${widget.badgeId}/invite'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Invite',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  // ── Cars section ──────────────────────────────────────────────────────────

  Widget _buildCarsSection(BadgeDetail badge, bool isCreator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registered Cars',
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: badge.cars.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No cars registered yet',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: badge.cars.asMap().entries.map((entry) {
                    final i   = entry.key;
                    final car = entry.value;
                    return Column(
                      children: [
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.divider,
                              indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHighlight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(LucideIcons.car,
                                      size: 18, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      car.plate,
                                      style: AppTypography.mono.copyWith(
                                          color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      car.ownerName,
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
        if (isCreator && badge.slotsRemaining > 0) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context
                .push('/student/badges/${widget.badgeId}/add-car'),
            icon: const Icon(LucideIcons.plus,
                size: 16, color: AppColors.primary),
            label: Text('Add Car to Slot',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.primary)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ],
    );
  }

  // ── Action button ─────────────────────────────────────────────────────────

  Widget _buildActionButton(BadgeDetail badge) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: () =>
            context.push('/student/badges/${widget.badgeId}/invite'),
        icon: const Icon(LucideIcons.userPlus, size: 18),
        label: const Text('Invite Member'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.buttonRadius)),
          textStyle: AppTypography.labelLarge
              .copyWith(color: AppColors.background),
        ),
      ),
    );
  }

  // ── Shimmer ───────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _shimmerBlock(100),
        const SizedBox(height: 16),
        _shimmerBlock(160),
        const SizedBox(height: 16),
        _shimmerBlock(120),
      ],
    );
  }

  Widget _shimmerBlock(double height) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, _) => Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(_shimmerAnim.value - 0.5, 0),
            end:   Alignment(_shimmerAnim.value + 0.5, 0),
            colors: const [
              AppColors.surfaceLight,
              AppColors.surfaceHighlight,
              AppColors.surfaceLight,
            ],
          ).createShader(bounds),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}
