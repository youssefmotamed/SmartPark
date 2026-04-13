// profile_screen.dart — Student profile: avatar, info, points, badge, logout
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../providers/auth_provider.dart';

// ── Mock data ────────────────────────────────────────────────────────────────
// TODO: replace with ProfileService.getProfile() in Task 1.9 (Week 3)
const _mockUser = {
  'fullName': 'Walid Ahmed',
  'studentId': '20221234',
  'email': 'walid@student.aast.edu',
  'plateNumber': 'ABC 1234',
  'totalPoints': 85,
  'activeBadge': {
    'type': 'CARPOOL_3',
    'status': 'ACTIVE',
    'memberCount': 2,
    'totalSlots': 3,
  },
};

/// Student profile screen — shows identity, points, active badge, and logout.
///
/// Hosted in StudentShell tab index 3. No AppBar — the shell top bar
/// provides navigation context. Uses staggered entrance animations.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Staggered section animation helper ──────────────────────────────────────

  Widget _animated(Widget child, {required double delayMs}) {
    final start = delayMs / 400.0;
    final end = (start + 0.5).clamp(0.0, 1.0);

    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: child),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fullName    = _mockUser['fullName']  as String;
    final studentId   = _mockUser['studentId'] as String;
    final email       = _mockUser['email']     as String;
    final plate       = _mockUser['plateNumber'] as String;
    final points      = _mockUser['totalPoints'] as int;
    final badge       = _mockUser['activeBadge'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.screenV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1 · Avatar + name ──────────────────────────────────────────
            _animated(
              _buildHeader(fullName, studentId),
              delayMs: 0,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2 · Info card ──────────────────────────────────────────────
            _animated(
              _buildInfoCard(email, plate),
              delayMs: 80,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── 3 · Points card ────────────────────────────────────────────
            _animated(
              _buildPointsCard(points),
              delayMs: 160,
            ),
            const SizedBox(height: AppSpacing.sm + 4),

            // ── 4 · Badge card ─────────────────────────────────────────────
            _animated(
              _buildBadgeCard(badge),
              delayMs: 240,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── 5 · Logout button ──────────────────────────────────────────
            _animated(
              _buildLogoutButton(context),
              delayMs: 320,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section builders
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(String fullName, String studentId) {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    return Column(
      children: [
        // Avatar circle
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryGlow,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Text(
              initial,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(fullName, style: AppTypography.displaySmall, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          'ID: $studentId',
          style: AppTypography.mono.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String email, String plate) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Email row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                const Icon(LucideIcons.mail, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    email,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, color: AppColors.divider, indent: 46, endIndent: 0),
          // Plate row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                const Icon(LucideIcons.car, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Text(
                  plate,
                  style: AppTypography.mono.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(int points) {
    return _TappableCard(
      onTap: () => debugPrint('Navigate to Points — Phase 4'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 20, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      '$points',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('points available', style: AppTypography.bodySmall),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final memberCount = badge['memberCount'] as int;
    final totalSlots  = badge['totalSlots']  as int;

    return _TappableCard(
      onTap: () => debugPrint('Navigate to Badges — Phase 5'),
      accentLeft: AppColors.carpool3,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge type row
                Row(
                  children: [
                    const Icon(LucideIcons.creditCard, size: 18, color: AppColors.carpool3),
                    const SizedBox(width: 8),
                    Text('Carpool 3', style: AppTypography.labelMedium),
                  ],
                ),
                const SizedBox(height: 4),
                // Status row
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
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$memberCount of $totalSlots members',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, size: 18, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logout confirmation dialog ─────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text('Logout', style: AppTypography.displaySmall),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(
              'Logout',
              style: AppTypography.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable tappable card with optional left accent border
// ─────────────────────────────────────────────────────────────────────────────

class _TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? accentLeft;

  const _TappableCard({
    required this.child,
    required this.onTap,
    this.accentLeft,
  });

  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 1),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.accentLeft != null)
                    Container(width: 4, color: widget.accentLeft),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
