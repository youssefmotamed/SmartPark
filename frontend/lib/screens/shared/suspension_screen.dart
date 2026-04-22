// suspension_screen.dart — S35: Full-screen badge suspension notice.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/badge_summary.dart';
import '../../providers/badge_provider.dart';

/// S35 — Suspension notice screen.
///
/// Pushed as a full-screen overlay when the student's default badge is
/// SUSPENDED. Shows badge type, a generic reason, and a dismiss button.
/// Dismiss pops back to wherever the student came from.
class SuspensionScreen extends StatelessWidget {
  const SuspensionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badge = context.watch<BadgeProvider>().defaultBadge;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Center(
                child: Container(
                  width:  88,
                  height: 88,
                  decoration: BoxDecoration(
                    color:  AppColors.error.withValues(alpha: 0.12),
                    shape:  BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shieldOff,
                    size:  44,
                    color: AppColors.error,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Badge Suspended',
                style: AppTypography.displaySmall.copyWith(
                    color: AppColors.error),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Your parking badge has been suspended due to a parking violation.',
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Badge info card
              if (badge != null)
                _BadgeInfoCard(badge: badge),

              const SizedBox(height: 28),

              // Reason box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:  AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.info,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reason: Parking violation\n'
                        'Contact the campus admin to appeal or get more details.',
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Dismiss button
              ElevatedButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/student/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius)),
                ),
                child: Text(
                  'Understood',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.background),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge info card
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeInfoCard extends StatelessWidget {
  final BadgeSummary badge;

  const _BadgeInfoCard({required this.badge});

  static String _formatBadgeType(String type) {
    switch (type) {
      case 'INDIVIDUAL': return 'Individual Badge';
      case 'CARPOOL_2':  return 'Carpool (2-Person)';
      case 'CARPOOL_3':  return 'Carpool (3-Person)';
      case 'CARPOOL_4':  return 'Carpool (4-Person)';
      case 'CARPOOL_5':  return 'Carpool (5-Person)';
      default:           return type.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color:  AppColors.error.withValues(alpha: 0.12),
              shape:  BoxShape.circle,
            ),
            child: const Icon(LucideIcons.creditCard,
                size: 20, color: AppColors.error),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatBadgeType(badge.badgeType),
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Badge #${badge.badgeId}  ·  ${badge.pointsBalance} pts',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Suspended',
              style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
