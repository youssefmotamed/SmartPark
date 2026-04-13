// reservation_cancelled_screen.dart — Success screen shown after a reservation is cancelled
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';

/// Shown after a student successfully cancels their reservation.
///
/// Replaces the previous pattern of navigating directly to /student/home,
/// which caused a black-screen flash. Gives the user clear confirmation
/// and a single action: return to the map.
class ReservationCancelledScreen extends StatelessWidget {
  const ReservationCancelledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.screenV,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.xCircle,
                    size: 40,
                    color: AppColors.error,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                'Reservation Cancelled',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                'Your reservation has been cancelled successfully.\nThe spot is now available to others.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Return to home button
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/student/home'),
                  icon: const Icon(LucideIcons.mapPin, size: 18),
                  label: const Text('Return to Home'),
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

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
