// guard_home_screen.dart — S21: Guard home dashboard with quick action cards
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../providers/auth_provider.dart';

/// S21 — Guard Home dashboard.
///
/// Displays a welcome greeting, 4 quick-action cards (Scan QR navigates to
/// /guard/scanner; the other 3 show a "Coming in Phase 6" SnackBar), and a
/// today's-at-a-glance summary row with placeholder stat values.
class GuardHomeScreen extends StatelessWidget {
  const GuardHomeScreen({super.key});

  static const List<_ActionData> _actions = [
    _ActionData(
      icon:  LucideIcons.qrCode,
      label: 'Scan QR',
      sub:   'Entry & Exit',
      route: '/guard/scanner',
      color: AppColors.primary,
    ),
    _ActionData(
      icon:  LucideIcons.clipboardList,
      label: 'Active List',
      sub:   'View reservations',
      route: '/guard/active',
      color: AppColors.warning,
    ),
    _ActionData(
      icon:  LucideIcons.parkingCircle,
      label: 'Guest Parking',
      sub:   'Zone C management',
      route: '/guard/guest-parking',
      color: AppColors.success,
    ),
    _ActionData(
      icon:  LucideIcons.alertTriangle,
      label: 'Report Violation',
      sub:   'Flag an issue',
      route: '/guard/violation',
      color: AppColors.error,
    ),
  ];

  static const List<_StatData> _stats = [
    _StatData(value: '--', label: 'Scanned',    color: AppColors.primary),
    _StatData(value: '--', label: 'Guest',      color: AppColors.warning),
    _StatData(value: '--', label: 'Violations', color: AppColors.error),
  ];

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final firstName = auth.currentUser?.fullName.split(' ').first ?? 'Guard';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical:   AppSpacing.screenV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Welcome header ──────────────────────────────────────────
              Text(
                'Welcome back,',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(firstName, style: AppTypography.displaySmall),
              const SizedBox(height: 28),

              // ── Quick Actions ────────────────────────────────────────────
              Text(
                'Quick Actions',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                physics:        const NeverScrollableScrollPhysics(),
                shrinkWrap:     true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing:  12,
                childAspectRatio: 1.0,
                children: _actions.map((data) {
                  return _ActionCard(
                    data: data,
                    onTap: () => context.go(data.route),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── Today's summary ──────────────────────────────────────────
              Text(
                'Today',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color:        AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border:       Border.all(color: AppColors.divider),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    for (int i = 0; i < _stats.length; i++) ...[
                      if (i != 0)
                        Container(
                          width: 1, height: 40,
                          color: AppColors.divider,
                        ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _stats[i].value,
                              style: AppTypography.displaySmall.copyWith(
                                color: _stats[i].color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_stats[i].label, style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _ActionData {
  final IconData icon;
  final String   label;
  final String   sub;
  final String   route;
  final Color    color;
  const _ActionData({
    required this.icon,
    required this.label,
    required this.sub,
    required this.route,
    required this.color,
  });
}

class _StatData {
  final String value;
  final String label;
  final Color  color;
  const _StatData({
    required this.value,
    required this.label,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Action card
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatefulWidget {
  final _ActionData  data;
  final VoidCallback onTap;

  const _ActionCard({required this.data, required this.onTap});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown:   (_) => setState(() => _isPressed = true),
      onTapUp:     (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale:    _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color:        AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border:       Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width:  56,
                height: 56,
                decoration: BoxDecoration(
                  color: d.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(d.icon, size: 28, color: d.color),
              ),
              const SizedBox(height: 12),
              Text(d.label, style: AppTypography.labelMedium),
              const SizedBox(height: 2),
              Text(d.sub, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
