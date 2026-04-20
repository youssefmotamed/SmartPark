// invitation_screen.dart — S20: Invitation Received screen for carpool badge
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/badge_detail.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';

/// S20 — Invitation Received screen.
///
/// Shown when a student taps a CARPOOL_INVITE notification. Loads the
/// badge detail, displays the badge info and current members, then lets
/// the student accept (POST /badges/{id}/accept) or decline (pop only).
class InvitationScreen extends StatefulWidget {
  final int badgeId;
  const InvitationScreen({super.key, required this.badgeId});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BadgeProvider>().loadBadgeDetail(widget.badgeId).then((_) {
        if (!mounted) return;
        _checkIfAlreadyAccepted();
      });
    });
  }

  /// If the current user is already an ACCEPTED member, skip the invite UI.
  void _checkIfAlreadyAccepted() {
    final badge         = context.read<BadgeProvider>().selectedBadge;
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    if (badge == null || currentUserId == null) return;

    final alreadyAccepted = badge.members.any(
      (m) => m.userId == currentUserId && m.status == 'ACCEPTED',
    );
    if (alreadyAccepted) setState(() => _accepted = true);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _badgeTierColor(String badgeType) {
    switch (badgeType) {
      case 'CARPOOL_2': return AppColors.carpool2;
      case 'CARPOOL_3': return AppColors.carpool3;
      case 'CARPOOL_4': return AppColors.carpool4;
      case 'CARPOOL_5': return AppColors.carpool5;
      default:          return AppColors.individual;
    }
  }

  String _badgeDisplayName(String badgeType) {
    switch (badgeType) {
      case 'INDIVIDUAL': return 'Individual';
      case 'CARPOOL_2':  return 'Carpool 2';
      case 'CARPOOL_3':  return 'Carpool 3';
      case 'CARPOOL_4':  return 'Carpool 4';
      case 'CARPOOL_5':  return 'Carpool 5';
      default:           return badgeType;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ── Action ────────────────────────────────────────────────────────────────

  Future<void> _handleAccept() async {
    final provider = context.read<BadgeProvider>();

    final success = await provider.acceptInvitation(widget.badgeId);

    if (!mounted) return;

    if (success) {
      setState(() => _accepted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.operationError ?? 'Failed to accept invitation'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_accepted) return _buildSuccessScreen();

    final provider = context.watch<BadgeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
            onPressed: () => context.pop(),
          ),
        ],
        title: Text('Invitation Received', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: provider.isLoadingDetail
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : provider.detailError != null && provider.selectedBadge == null
              ? _buildError(provider)
              : provider.selectedBadge == null
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _buildContent(provider, provider.selectedBadge!),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(38),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  LucideIcons.checkCircle,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "You're in!",
                style: AppTypography.displayMedium
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You are a member of this carpool badge.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your car is registered and ready to use.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      context.pushReplacement('/student/badges/${widget.badgeId}'),
                  child: Text(
                    'View Badge',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.background),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go('/student/home'),
                  child: Text(
                    'Go to My Badges',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError(BadgeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.detailError ?? 'Failed to load invitation details',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<BadgeProvider>().loadBadgeDetail(widget.badgeId),
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
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(BadgeProvider provider, BadgeDetail badge) {
    final tierColor   = _badgeTierColor(badge.badgeType);
    final displayName = _badgeDisplayName(badge.badgeType);
    final accepted    = badge.members.where((m) => m.isAccepted).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Invitation icon + headline ──────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(LucideIcons.users,
                      size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  "You've been invited!",
                  style: AppTypography.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'to join a carpool badge',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Badge info card ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: type + status pill
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Row(
                    children: [
                      Text(
                        displayName,
                        style: AppTypography.labelLarge
                            .copyWith(color: tierColor),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge.status,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.success,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.divider),

                // Info rows
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: LucideIcons.users,
                        label: 'Members',
                        value: '${badge.acceptedMemberCount}/${badge.maxSlots}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: LucideIcons.car,
                        label: 'Cars registered',
                        value: '${badge.acceptedMemberCars.length}',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: LucideIcons.star,
                        label: 'Points balance',
                        value: '${badge.pointsBalance} pts',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: LucideIcons.calendar,
                        label: 'Expires',
                        value: _formatDate(badge.expiresAt),
                      ),
                    ],
                  ),
                ),

                // Members preview
                if (accepted.isNotEmpty) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Members',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Avatar row — show up to 3
                            ...accepted.take(3).map((m) {
                              final name    = m.name ?? '?';
                              final initial = name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?';
                              return Container(
                                width: 36,
                                height: 36,
                                margin:
                                    const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: tierColor.withAlpha(51),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background,
                                      width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: AppTypography.labelSmall
                                        .copyWith(color: tierColor),
                                  ),
                                ),
                              );
                            }),
                            if (accepted.length > 3) ...[
                              const SizedBox(width: 4),
                              Text(
                                '+${accepted.length - 3} more',
                                style: AppTypography.bodySmall
                                    .copyWith(
                                        color: AppColors.textTertiary),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You'll be member ${badge.acceptedMemberCount + 1}"
                          ' of ${badge.maxSlots}',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Warning banner ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(26),
              border: Border.all(color: AppColors.warning.withAlpha(77)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.alertTriangle,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Accepting this invitation will register your car to this badge. '
                    'Make sure you have a car registered on your account.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Accept button ───────────────────────────────────────────
          SizedBox(
            height: AppSpacing.buttonHeight,
            child: ElevatedButton(
              onPressed: provider.isAccepting ? null : _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.surfaceHighlight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: provider.isAccepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.checkCircle2, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Accept Invitation',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.background),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Decline button ──────────────────────────────────────────
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Decline',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Info row ──────────────────────────────────────────────────────────────

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
