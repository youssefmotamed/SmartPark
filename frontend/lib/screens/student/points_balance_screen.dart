// points_balance_screen.dart — S10: Points balance overview for SmartPark students
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/points_balance.dart';
import '../../models/points_summary.dart';
import '../../providers/points_provider.dart';

/// S10 — Points Balance screen.
///
/// Read-only overview of the student's current points status showing:
/// - Hero: large points number + badge multiplier pill
/// - Summary row: total earned / spent / expiring soon
/// - Actions: View History and Rewards Store
///
/// Loads [PointsProvider.loadBalanceAndSummary] on open.
class PointsBalanceScreen extends StatefulWidget {
  const PointsBalanceScreen({super.key});

  @override
  State<PointsBalanceScreen> createState() => _PointsBalanceScreenState();
}

class _PointsBalanceScreenState extends State<PointsBalanceScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PointsProvider>().loadBalanceAndSummary().then((_) {
        if (mounted) _animController.forward();
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _tierColor(String badgeType) {
    switch (badgeType) {
      case 'CARPOOL_2': return AppColors.carpool2;
      case 'CARPOOL_3': return AppColors.carpool3;
      case 'CARPOOL_4': return AppColors.carpool4;
      case 'CARPOOL_5': return AppColors.carpool5;
      default:          return AppColors.individual;
    }
  }

  String _tierLabel(String badgeType) =>
      badgeType.replaceAll('_', ' ');

  String _multiplierLabel(double m) =>
      '${m.toStringAsFixed(1)}×';

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PointsProvider>();
    final loading  = provider.isLoadingBalance || provider.isLoadingSummary;

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
        title: Text('Points', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: () {
        if (loading && provider.balance == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (provider.error != null && provider.balance == null) {
          return _buildError(provider);
        }
        return _buildContent(provider.balance!, provider.summary!);
      }(),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────────

  Widget _buildError(PointsProvider provider) {
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
            onPressed: () => context.read<PointsProvider>().loadBalanceAndSummary(),
            child: Text(
              'Retry',
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loaded content ────────────────────────────────────────────────────────────

  Widget _buildContent(PointsBalance balance, PointsSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical:   AppSpacing.screenV,
      ),
      child: FadeTransition(
        opacity: _animController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildHero(balance),
            const SizedBox(height: 32),
            _buildSummaryRow(summary),
            const SizedBox(height: 32),
            _buildActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Hero section ──────────────────────────────────────────────────────────────

  Widget _buildHero(PointsBalance balance) {
    final tierColor = _tierColor(balance.badgeType);

    return Column(
      children: [
        // Radial glow behind points number
        Container(
          width:  180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.background.withValues(alpha: 0.0),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Points number
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: balance.pointsBalance),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => Text(
                  '$value',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize:   56,
                    color:      AppColors.primary,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Text(
                'points',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Badge multiplier pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:        tierColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tierColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            '${_tierLabel(balance.badgeType)} · ${_multiplierLabel(balance.multiplier)} multiplier',
            style: AppTypography.labelSmall.copyWith(color: tierColor),
          ),
        ),
      ],
    );
  }

  // ── Summary row ───────────────────────────────────────────────────────────────

  Widget _buildSummaryRow(PointsSummary summary) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(
          value: summary.totalEarned,
          label: 'Earned',
          color: AppColors.success,
        )),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(
          value: summary.totalSpent,
          label: 'Spent',
          color: AppColors.error,
        )),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(
          value: summary.expiringSoon,
          label: 'Expiring',
          color: AppColors.warning,
        )),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // View History
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/student/points/history'),
            icon:  const Icon(LucideIcons.history, size: 18),
            label: const Text('View History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              textStyle: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Rewards Store
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/student/rewards'),
            icon:  const Icon(LucideIcons.gift, size: 18),
            label: const Text('Rewards Store'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              textStyle: AppTypography.labelLarge.copyWith(
                color: AppColors.background,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary card
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int    value;
  final String label;
  final Color  color;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Colored top accent line
          Container(height: 3, color: color),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  '$value',
                  style: AppTypography.displaySmall.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(label, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
