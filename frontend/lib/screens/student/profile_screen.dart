// profile_screen.dart — Student profile screen
// Split layout: dark navy header (amber avatar + name + ID), light card area below.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/badge_provider.dart';
import '../../services/base_api_service.dart';
import '../../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animController;

  ProfileResponse? _profile;
  bool    _isLoading = true;
  String? _error;

  // ── Light card palette ─────────────────────────────────────────────────────
  static const _kPageBg    = Color(0xFFEEF1F7);
  static const _kCardBg    = Colors.white;
  static const _kCardText  = Color(0xFF1A2035);
  static const _kCardSub   = Color(0xFF6B7280);
  static const _kAmber     = Color(0xFFEDB82A);
  static const _kDivider   = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BadgeProvider>();
      if (bp.badges.isEmpty) {
        bp.loadBadges().then((_) => bp.loadDefaultBadgePreference());
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final profile = await ProfileService().getProfile();
      if (!mounted) return;
      setState(() { _profile = profile; _isLoading = false; });
      _animController.forward(from: 0);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _isLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Connection error. Check your network.'; _isLoading = false; });
    }
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
      case 'CARPOOL_2': return '1.2×';
      case 'CARPOOL_3': return '1.4×';
      case 'CARPOOL_4': return '1.6×';
      case 'CARPOOL_5': return '1.8×';
      default:          return '1×';
    }
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: _kCardText)),
        content: Text('Are you sure you want to log out?',
            style: GoogleFonts.manrope(color: _kCardSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.manrope(color: _kCardSub, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              final router = GoRouter.of(context);
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              router.go('/login');
            },
            child: Text('Log Out',
                style: GoogleFonts.manrope(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: _kAmber)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(_error!,
                  style: GoogleFonts.manrope(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAmber,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Retry',
                    style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final p           = _profile!;
    final bp          = context.watch<BadgeProvider>();
    final badge       = bp.defaultBadge;
    final points      = badge?.pointsBalance ?? p.totalPoints;
    final initial     = p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _animController,
        child: Column(
          children: [
            // ── Dark hero area ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 28, 0, 28),
              child: Column(
                children: [
                  // Amber avatar circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: _kAmber,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.manrope(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    p.fullName,
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${p.studentId}',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.white.withAlpha(150),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // ── Light card area ────────────────────────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _kPageBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── ACCOUNT INFO ──────────────────────────────────────
                      _sectionLabel('ACCOUNT INFO'),
                      const SizedBox(height: 10),
                      _buildAccountCard(p.email, p.plateNumber),
                      const SizedBox(height: 12),

                      // ── Points Balance ────────────────────────────────────
                      _buildNavCard(
                        onTap: () => context.push('/student/points'),
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _kAmber.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.star_rounded,
                              color: _kAmber, size: 22),
                        ),
                        title: 'Points Balance',
                        subtitle: '$points pts',
                      ),
                      const SizedBox(height: 10),

                      // ── Active Badge ──────────────────────────────────────
                      _buildNavCard(
                        onTap: () => context.push('/student/badges'),
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: (badge != null
                                    ? _tierColor(badge.badgeType)
                                    : AppColors.individual)
                                .withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.shield,
                            color: badge != null
                                ? _tierColor(badge.badgeType)
                                : AppColors.individual,
                            size: 20,
                          ),
                        ),
                        title: 'Active Badge',
                        subtitle: badge != null
                            ? _badgeLabel(badge.badgeType)
                            : 'No badge',
                        trailingChip: badge != null
                            ? _multiplierLabel(badge.badgeType)
                            : null,
                        trailingChipColor: badge != null
                            ? _tierColor(badge.badgeType)
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // ── Reservation History ───────────────────────────────
                      _buildNavCard(
                        onTap: () => context.go('/student/history'),
                        title: 'Reservation History',
                      ),
                      const SizedBox(height: 24),

                      // ── Log Out ───────────────────────────────────────────
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kCardSub,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildAccountCard(String email, String plate) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Email row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                const Icon(LucideIcons.mail, size: 18, color: _kCardSub),
                const SizedBox(width: 12),
                Text('Email',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w500, color: _kCardText)),
                const Spacer(),
                Text(email,
                    style: GoogleFonts.manrope(
                        fontSize: 13, color: _kCardSub)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          // Plate row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                const Icon(LucideIcons.car, size: 18, color: _kAmber),
                const SizedBox(width: 12),
                Text('License Plate',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w500, color: _kCardText)),
                const Spacer(),
                Text(
                  plate,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kAmber,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required VoidCallback onTap,
    Widget? leading,
    required String title,
    String? subtitle,
    String? trailingChip,
    Color? trailingChipColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kCardSub,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          subtitle,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kCardText,
                          ),
                        ),
                        if (trailingChip != null && trailingChipColor != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: trailingChipColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              trailingChip,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: trailingChipColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 22, color: _kCardSub),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.logOut, size: 18, color: AppColors.error.withAlpha(200)),
            const SizedBox(width: 8),
            Text(
              'Log Out',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
