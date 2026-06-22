// badge_list_screen.dart — S15: Badge list screen
// Light gray page background, white badge cards with shield icon + tier color.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/badge_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';

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

  static const _kPageBg   = Color(0xFFEEF1F7);
  static const _kCardText = Color(0xFF1A2035);
  static const _kCardSub  = Color(0xFF6B7280);
  static const _kNavy     = Color(0xFF1A2035);

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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _tierColor(String t) {
    switch (t) {
      case 'CARPOOL_2': return AppColors.carpool2;
      case 'CARPOOL_3': return AppColors.carpool3;
      case 'CARPOOL_4': return AppColors.carpool4;
      case 'CARPOOL_5': return AppColors.carpool5;
      default:          return AppColors.individual;
    }
  }

  String _badgeLabel(String t) {
    switch (t) {
      case 'INDIVIDUAL': return 'Individual';
      case 'CARPOOL_2':  return 'Carpool 2';
      case 'CARPOOL_3':  return 'Carpool 3';
      case 'CARPOOL_4':  return 'Carpool 4';
      case 'CARPOOL_5':  return 'Carpool 5';
      default:           return t;
    }
  }

  String _multiplierLabel(String t) {
    switch (t) {
      case 'CARPOOL_2': return '1.2× points';
      case 'CARPOOL_3': return '1.4× points';
      case 'CARPOOL_4': return '1.6× points';
      case 'CARPOOL_5': return '1.8× points';
      default:          return '1× points';
    }
  }

  bool _isPending(BadgeSummary badge, int? uid) {
    if (uid == null) return false;
    return badge.members.any((m) => m.userId == uid && m.status == 'PENDING');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BadgeProvider>();

    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'My Badges',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/student/badges/create'),
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New Badge',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(BadgeProvider provider) {
    if (provider.isLoadingBadges && provider.badges.isEmpty) {
      return _buildShimmer();
    }
    if (provider.badgesError != null && provider.badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(provider.badgesError!, textAlign: TextAlign.center,
                style: GoogleFonts.manrope(color: _kCardSub)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<BadgeProvider>().loadBadges(),
              child: Text('Retry',
                  style: GoogleFonts.manrope(
                      color: AppColors.individual, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    if (provider.badges.isEmpty) return _buildEmpty();

    final uid        = context.read<AuthProvider>().currentUser?.id;
    final defaultId  = provider.defaultBadgeId ??
        provider.badges.where((b) => b.status == 'ACTIVE').firstOrNull?.badgeId;

    return RefreshIndicator(
      color: AppColors.individual,
      onRefresh: () => context.read<BadgeProvider>().loadBadges(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: provider.badges.length,
        itemBuilder: (_, i) {
          final badge   = provider.badges[i];
          final pending = _isPending(badge, uid);
          final isPrimary = badge.badgeId == defaultId;
          return _BadgeCard(
            badge:       badge,
            tierColor:   pending ? AppColors.warning : _tierColor(badge.badgeType),
            badgeLabel:  _badgeLabel(badge.badgeType),
            multiplier:  _multiplierLabel(badge.badgeType),
            isPending:   pending,
            isPrimary:   isPrimary && !pending,
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.individual.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.shield, size: 32, color: AppColors.individual),
          ),
          const SizedBox(height: 20),
          Text('No badges yet',
              style: GoogleFonts.manrope(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _kCardText)),
          const SizedBox(height: 8),
          Text('Create a badge to start parking',
              style: GoogleFonts.manrope(fontSize: 14, color: _kCardSub)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: List.generate(3, (i) => _ShimmerCard(anim: _shimmerAnim)),
    );
  }
}

// ── Badge card ────────────────────────────────────────────────────────────────

class _BadgeCard extends StatelessWidget {
  final BadgeSummary badge;
  final Color        tierColor;
  final String       badgeLabel;
  final String       multiplier;
  final bool         isPending;
  final bool         isPrimary;

  const _BadgeCard({
    required this.badge,
    required this.tierColor,
    required this.badgeLabel,
    required this.multiplier,
    this.isPending = false,
    this.isPrimary = false,
  });

  Color _statusColor() {
    switch (badge.status) {
      case 'ACTIVE':    return const Color(0xFF2E7D32);
      case 'SUSPENDED': return AppColors.error;
      default:          return AppColors.unavailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return GestureDetector(
      onTap: () => isPending
          ? context.push('/student/badges/${badge.badgeId}/accept')
          : context.push('/student/badges/${badge.badgeId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Pending banner ───────────────────────────────────────────────
            if (isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(30),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mail, size: 14, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Invitation pending — tap to accept',
                      style: GoogleFonts.manrope(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Main content ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shield icon in tier-colored rounded square
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: tierColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.shield, color: tierColor, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Badge name + status chips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badgeLabel,
                          style: GoogleFonts.manrope(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A2035),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Active / status chip
                            _Chip(
                              label: badge.status,
                              color: statusColor,
                              filled: false,
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 6),
                              _Chip(
                                label: 'Primary',
                                color: const Color(0xFF5C6BC0),
                                filled: false,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Points on the right
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFEDB82A), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${badge.pointsBalance}',
                            style: GoogleFonts.manrope(
                              fontSize: 20, fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A2035),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'pts',
                        style: GoogleFonts.manrope(
                          fontSize: 11, color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Divider + bottom row ─────────────────────────────────────────
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(LucideIcons.users, size: 14, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    '${badge.acceptedMemberCount}/${badge.maxSlots} members',
                    style: GoogleFonts.manrope(
                      fontSize: 13, color: const Color(0xFF6B7280),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tierColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      multiplier,
                      style: GoogleFonts.manrope(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: tierColor,
                      ),
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

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   filled;
  const _Chip({required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  final Animation<double> anim;
  const _ShimmerCard({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, _) => ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(anim.value - 0.5, 0),
            end:   Alignment(anim.value + 0.5, 0),
            colors: const [
              Color(0xFFF5F5F5),
              Color(0xFFEEEEEE),
              Color(0xFFF5F5F5),
            ],
          ).createShader(bounds),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}
