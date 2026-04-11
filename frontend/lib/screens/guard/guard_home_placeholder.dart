// guard_home_placeholder.dart — Guard dashboard placeholder (Phase 2)
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';

/// Placeholder shown in the Scan tab until the real guard dashboard is built in Phase 2.
class GuardHomePlaceholder extends StatelessWidget {
  const GuardHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(LucideIcons.qrCode, size: 36, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            Text('Guard Dashboard', style: AppTypography.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 2',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
