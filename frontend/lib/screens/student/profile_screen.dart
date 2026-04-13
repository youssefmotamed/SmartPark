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
import '../../services/base_api_service.dart';
import '../../services/profile_service.dart';

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

  ProfileResponse? _profile;
  bool    _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

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
      setState(() {
        _error = 'Connection error. Check your network.';
        _isLoading = false;
      });
    }
  }

  // ── Staggered section animation helper ──────────────────────────────────────

  Widget _animated(Widget child, {required double delayMs}) {
    final start = delayMs / 400.0;
    final end   = (start + 0.5).clamp(0.0, 1.0);

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

  // ── Badge helpers ─────────────────────────────────────────────────────────────

  Color _badgeBorderColor(String? type) {
    switch (type) {
      case 'CARPOOL_2': return AppColors.carpool2;
      case 'CARPOOL_3': return AppColors.carpool3;
      case 'CARPOOL_4': return AppColors.carpool4;
      case 'CARPOOL_5': return AppColors.carpool5;
      default:          return AppColors.individual;
    }
  }

  String _badgeDisplayName(String? type) {
    switch (type) {
      case 'CARPOOL_2': return 'Carpool 2';
      case 'CARPOOL_3': return 'Carpool 3';
      case 'CARPOOL_4': return 'Carpool 4';
      case 'CARPOOL_5': return 'Carpool 5';
      default:          return 'Individual';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    return _buildContent();
  }

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(_error!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: Text('Retry', style: AppTypography.labelMedium.copyWith(color: AppColors.background)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _profile!;

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
            _animated(_buildHeader(p.fullName, p.studentId), delayMs: 0),
            const SizedBox(height: AppSpacing.lg),

            // ── 2 · Info card ──────────────────────────────────────────────
            _animated(_buildInfoCard(p.email, p.plateNumber), delayMs: 80),
            const SizedBox(height: AppSpacing.md),

            // ── 3 · Points card ────────────────────────────────────────────
            _animated(_buildPointsCard(p.totalPoints), delayMs: 160),
            const SizedBox(height: AppSpacing.sm + 4),

            // ── 4 · Badge card ─────────────────────────────────────────────
            _animated(_buildBadgeCard(p.activeBadge), delayMs: 240),
            const SizedBox(height: AppSpacing.sm + 4),

            // ── 5 · History button ─────────────────────────────────────────
            _animated(_buildHistoryButton(context), delayMs: 320),
            const SizedBox(height: AppSpacing.xl),

            // ── 6 · Logout button ──────────────────────────────────────────
            _animated(_buildLogoutButton(context), delayMs: 400),
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
          const Divider(height: 1, color: AppColors.divider, indent: 46),
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

  Widget _buildBadgeCard(ActiveBadgeInfo? badge) {
    final type        = badge?.type;
    final status      = badge?.status ?? 'ACTIVE';
    final accentColor = _badgeBorderColor(type);
    final displayName = _badgeDisplayName(type);
    final isActive    = status == 'ACTIVE';

    // TODO: fetch full badge details from GET /badges/{id} for member count

    return _TappableCard(
      onTap: () => debugPrint('Navigate to Badges — Phase 5'),
      accentLeft: accentColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.creditCard, size: 18, color: accentColor),
                    const SizedBox(width: 8),
                    Text(displayName, style: AppTypography.labelMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.success : AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Active' : status,
                      style: AppTypography.bodySmall.copyWith(
                        color: isActive ? AppColors.success : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return _TappableCard(
      onTap: () => context.go('/student/history'),
      child: Row(
        children: [
          const Icon(LucideIcons.history, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Reservation History', style: AppTypography.labelMedium),
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
            Text('Logout', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
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
        content: Text('Are you sure you want to logout?', style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
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
      onTapUp:   (_) => setState(() => _pressed = false),
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
