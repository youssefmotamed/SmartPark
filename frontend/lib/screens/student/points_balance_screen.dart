// points_balance_screen.dart — S10: Points balance overview
// Split layout: dark navy hero (star + balance + multiplier), light card area below.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/points_summary.dart';
import '../../providers/badge_provider.dart';
import '../../providers/points_provider.dart';

class PointsBalanceScreen extends StatefulWidget {
  final bool showAppBar;
  const PointsBalanceScreen({super.key, this.showAppBar = true});

  @override
  State<PointsBalanceScreen> createState() => _PointsBalanceScreenState();
}

class _PointsBalanceScreenState extends State<PointsBalanceScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animController;

  // ── Light card palette ─────────────────────────────────────────────────────
  static const _kPageBg     = Color(0xFFEEF1F7);
  static const _kCardBg     = Colors.white;
  static const _kCardText   = Color(0xFF1A2035);
  static const _kCardSub    = Color(0xFF6B7280);
  static const _kAmber      = Color(0xFFEDB82A);
  static const _kGreen      = Color(0xFF2E7D32);
  static const _kGreenLight = Color(0xFF4CAF50);
  static const _kRed        = Color(0xFFD32F2F);
  static const _kOrange     = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final badgeProvider = context.read<BadgeProvider>();
      if (badgeProvider.badges.isEmpty) {
        badgeProvider.loadBadges().then((_) {
          badgeProvider.loadDefaultBadgePreference();
          if (mounted) _animController.forward();
        });
      } else {
        _animController.forward();
      }
      context.read<PointsProvider>().loadBalanceAndSummary();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _multiplierFromType(String t) {
    switch (t) {
      case 'CARPOOL_2': return 1.2;
      case 'CARPOOL_3': return 1.4;
      case 'CARPOOL_4': return 1.6;
      case 'CARPOOL_5': return 1.8;
      default:          return 1.0;
    }
  }

  String _badgeLabel(String t) {
    switch (t) {
      case 'CARPOOL_2': return 'Carpool 2';
      case 'CARPOOL_3': return 'Carpool 3';
      case 'CARPOOL_4': return 'Carpool 4';
      case 'CARPOOL_5': return 'Carpool 5';
      default:          return 'Individual';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final badgeProvider  = context.watch<BadgeProvider>();
    final pointsProvider = context.watch<PointsProvider>();
    final defaultBadge   = badgeProvider.defaultBadge;

    if (badgeProvider.isLoadingBadges && badgeProvider.badges.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: _kAmber)),
      );
    }

    final balance    = defaultBadge?.pointsBalance ?? 0;
    final badgeType  = defaultBadge?.badgeType ?? 'INDIVIDUAL';
    final multiplier = _multiplierFromType(badgeType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Points',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: Column(
        children: [
          // ── Dark hero area ───────────────────────────────────────────────
          Expanded(
            flex: 42,
            child: _buildHero(balance, multiplier, badgeType),
          ),

          // ── Light card area ──────────────────────────────────────────────
          Expanded(
            flex: 58,
            child: Container(
              decoration: const BoxDecoration(
                color: _kPageBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: FadeTransition(
                opacity: _animController,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryCard(pointsProvider.summary, pointsProvider.isLoadingSummary),
                      const SizedBox(height: 16),
                      _buildRewardsButton(),
                      const SizedBox(height: 12),
                      _buildHistoryButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero section ───────────────────────────────────────────────────────────

  Widget _buildHero(int balance, double multiplier, String badgeType) {
    return FadeTransition(
      opacity: _animController,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Star icon
          const Icon(Icons.star_rounded, color: _kAmber, size: 44),
          const SizedBox(height: 12),

          // Animated balance counter
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => Text(
              '$value',
              style: GoogleFonts.manrope(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: _kAmber,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            'points available',
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: Colors.white.withAlpha(160),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // Multiplier pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shield, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${multiplier.toStringAsFixed(1)}× multiplier · ${_badgeLabel(badgeType)}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary card ───────────────────────────────────────────────────────────

  Widget _buildSummaryCard(PointsSummary? summary, bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Total Earned ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                // Green icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kGreenLight.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: _kGreenLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earned',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kCardSub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    isLoading || summary == null
                        ? const SizedBox(
                            width: 80,
                            height: 24,
                            child: LinearProgressIndicator(
                              color: _kGreen,
                              backgroundColor: Color(0xFFE8F5E9),
                            ),
                          )
                        : RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '+${summary.totalEarned}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: _kGreen,
                                  ),
                                ),
                                TextSpan(
                                  text: '  pts',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _kCardSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          // ── Spent | Expiring ──────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildSubStat(
                    icon: Icons.trending_down_rounded,
                    iconColor: _kRed,
                    label: 'Spent',
                    value: isLoading || summary == null ? '-' : '${summary.totalSpent}',
                    valueColor: _kRed,
                  ),
                ),
                Container(
                  width: 1,
                  color: const Color(0xFFF0F0F0),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                ),
                Expanded(
                  child: _buildSubStat(
                    icon: Icons.access_time_rounded,
                    iconColor: _kOrange,
                    label: 'Expiring',
                    value: isLoading || summary == null ? '-' : '${summary.expiringSoon}',
                    valueColor: _kOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kCardSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────

  Widget _buildRewardsButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: () => context.push('/student/rewards'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAmber,
          foregroundColor: _kCardText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Rewards Store',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kCardText,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: () => context.push('/student/points/history'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kCardBg,
          foregroundColor: _kCardText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'View History',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kCardText,
          ),
        ),
      ),
    );
  }
}
