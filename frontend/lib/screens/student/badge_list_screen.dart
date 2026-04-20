// badge_list_screen.dart — S15: Badge list overview for SmartPark students
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../models/badge_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';

/// S15 — Badge List screen.
///
/// Shows all badges belonging to the student with tier colors, points balance,
/// member/slot counts, and status pills. Tapping a card pushes S16 (detail).
/// The + button pushes S17 (create badge).
class BadgeListScreen extends StatefulWidget {
  final bool showAppBar;
  const BadgeListScreen({super.key, this.showAppBar = true});

  @override
  State<BadgeListScreen> createState() => _BadgeListScreenState();
}

class _BadgeListScreenState extends State<BadgeListScreen>
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
      context.read<BadgeProvider>().loadBadges();
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
    if (parts.length == 2) return '${_capitalize(parts[0])} ${parts[1]}';
    return badgeType;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0]}${s.substring(1).toLowerCase()}';

  /// Returns true when the current user is a PENDING member of [badge].
  /// PENDING means they were invited but haven't accepted yet.
  bool _isPendingMember(BadgeSummary badge, int? currentUserId) {
    if (currentUserId == null) return false;
    return badge.members.any(
      (m) => m.userId == currentUserId && m.status == 'PENDING',
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BadgeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft,
                    color: AppColors.textSecondary),
                onPressed: () => context.pop(),
              ),
              title: Text('My Badges', style: AppTypography.displaySmall),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.plus, color: AppColors.primary),
                  onPressed: () => context.push('/student/badges/create'),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppColors.divider),
              ),
            )
          : null,
      floatingActionButton: !widget.showAppBar
          ? FloatingActionButton(
              onPressed: () => context.push('/student/badges/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              elevation: 2,
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: _buildBody(provider),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BadgeProvider provider) {
    if (provider.isLoadingBadges && provider.badges.isEmpty) {
      return _buildShimmer();
    }

    if (provider.badgesError != null && provider.badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.badgesError!,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<BadgeProvider>().loadBadges(),
              child: Text('Retry',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (provider.badges.isEmpty) {
      return _buildEmptyState();
    }

    final currentUserId =
        context.read<AuthProvider>().currentUser?.id;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => context.read<BadgeProvider>().loadBadges(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: provider.badges.length,
        itemBuilder: (_, i) {
          final badge     = provider.badges[i];
          final isPending = _isPendingMember(badge, currentUserId);
          return _BadgeCard(
            badge:      badge,
            tierColor:  isPending ? AppColors.warning : _tierColor(badge.badgeType),
            badgeLabel: _badgeLabel(badge.badgeType),
            isPending:  isPending,
          );
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.creditCard,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 20),
          Text(
            'No badges yet',
            style: AppTypography.displaySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a badge to start parking',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/student/badges/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text('Create Badge',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.background)),
          ),
        ],
      ),
    );
  }

  // ── Shimmer ───────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: List.generate(
        3,
        (i) => _ShimmerCard(anim: _shimmerAnim, delay: i * 80),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge card
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final BadgeSummary badge;
  final Color        tierColor;
  final String       badgeLabel;
  final bool         isPending;

  const _BadgeCard({
    required this.badge,
    required this.tierColor,
    required this.badgeLabel,
    this.isPending = false,
  });

  Color _statusColor() {
    switch (badge.status) {
      case 'ACTIVE':     return AppColors.success;
      case 'SUSPENDED':  return AppColors.error;
      default:           return AppColors.textTertiary; // EXPIRED
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive    = badge.status == 'ACTIVE';
    final statusColor = _statusColor();
    final slotsOpen   = badge.maxSlots - badge.acceptedMemberCount;
    final slotColor   = slotsOpen > 0
        ? AppColors.warning
        : AppColors.textTertiary;

    return GestureDetector(
      onTap: () => isPending
          ? context.push('/student/badges/${badge.badgeId}/accept')
          : context.push('/student/badges/${badge.badgeId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: (isActive || isPending)
              ? Border.all(color: tierColor.withValues(alpha: 0.35), width: 1.5)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Pending invitation banner
            if (isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: AppColors.warning.withAlpha(38),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mail, size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Invitation pending — tap to accept',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent strip
              Container(width: 4, color: tierColor),

              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: type + status pill ──────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              badgeLabel,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge.status,
                              style: AppTypography.labelSmall.copyWith(
                                color: statusColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Middle row: info chips ────────────────────────────
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: LucideIcons.star,
                            label: '${badge.pointsBalance} pts',
                          ),
                          _InfoChip(
                            icon: LucideIcons.users,
                            label:
                                '${badge.acceptedMemberCount}/${badge.maxSlots} members',
                          ),
                          if (badge.isCarpool)
                            _InfoChip(
                              icon: LucideIcons.car,
                              label: '${badge.maxSlots - badge.acceptedMemberCount} slots open',
                              color: slotColor,
                            ),
                        ],
                      ),

                      // ── Bottom row: active indicator ──────────────────────
                      if (isActive) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Active badge',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Chevron
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Icon(LucideIcons.chevronRight,
                      size: 18, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}

// ── Info chip helper ──────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: AppTypography.bodySmall.copyWith(color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer card
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  final Animation<double> anim;
  final int               delay;

  const _ShimmerCard({required this.anim, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.divider),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(anim.value - 0.5, 0),
                  end:   Alignment(anim.value + 0.5, 0),
                  colors: const [
                    AppColors.surfaceLight,
                    AppColors.surfaceHighlight,
                    AppColors.surfaceLight,
                  ],
                ).createShader(bounds),
                child: Container(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
