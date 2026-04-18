// rewards_screen.dart — S12: Rewards Store screen for SmartPark students
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../models/reward.dart';
import '../../providers/points_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../widgets/redeem_confirmation_sheet.dart';

/// S12 — Rewards Store screen.
///
/// Displays the rewards catalogue with live affordability flags and a
/// confirmation sheet (S13) before spending points.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardsProvider>().loadRewards();
      final points = context.read<PointsProvider>();
      if (points.balance == null) points.loadBalanceAndSummary();
    });
  }

  // ── Redeem flow ───────────────────────────────────────────────────────────

  Future<void> _showRedeemSheet(Reward reward, int balance) async {
    await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RedeemConfirmationSheet(
        reward: reward,
        currentBalance: balance,
        onConfirm: () => _handleRedeem(reward),
      ),
    );
  }

  Future<void> _handleRedeem(Reward reward) async {
    if (mounted) Navigator.of(context).pop();

    final provider = context.read<RewardsProvider>();
    final success = await provider.redeemReward(reward.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reward.rewardName} redeemed!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (provider.advanceReservationUnlocked) {
        provider.clearAdvanceReservationUnlock();
        context.push('/student/advance-reservation');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.redemptionError ?? 'Redemption failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rewardsProvider = context.watch<RewardsProvider>();
    final pointsProvider  = context.watch<PointsProvider>();
    final balance         = pointsProvider.balance?.pointsBalance;

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
        title: Text('Rewards Store', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          _buildBalanceHeader(balance),
          Expanded(child: _buildBody(rewardsProvider, balance ?? 0)),
        ],
      ),
    );
  }

  // ── Balance header ────────────────────────────────────────────────────────

  Widget _buildBalanceHeader(int? balance) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Available Balance',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          Row(
            children: [
              Text(
                balance != null ? '$balance' : '--',
                style: AppTypography.displaySmall
                    .copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              Text(
                'pts',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(RewardsProvider provider, int balance) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.error != null && provider.rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<RewardsProvider>().loadRewards(),
              child: Text('Retry',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (provider.rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.gift,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No rewards available',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ...provider.rewards.map(
          (r) => _RewardCard(
            reward: r,
            onRedeem: () => _showRedeemSheet(r, balance),
          ),
        ),
        _ComingSoonCard(),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reward card
// ─────────────────────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final Reward reward;
  final VoidCallback onRedeem;

  const _RewardCard({required this.reward, required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + name/description ────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.star,
                        size: 22, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.rewardName,
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.description,
                        style: AppTypography.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),

            // ── Bottom row: cost + button ────────────────────────────────────
            Row(
              children: [
                const Icon(LucideIcons.coins,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  '${reward.pointsCost} pts',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.warning),
                ),
                const Spacer(),
                _buildButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton() {
    if (!reward.active) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Coming Soon',
          style: AppTypography.labelSmall
              .copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    if (!reward.canAfford) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.divider),
          foregroundColor: AppColors.textTertiary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Not enough pts',
          style: AppTypography.labelSmall
              .copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onRedeem,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.background,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Redeem',
        style: AppTypography.labelSmall
            .copyWith(color: AppColors.background),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static "coming soon" Merchant Vouchers card
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.ticket,
                          size: 22, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merchant Vouchers',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discounts at campus cafeteria and bookstore',
                          style: AppTypography.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              Text(
                'Coming soon',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
