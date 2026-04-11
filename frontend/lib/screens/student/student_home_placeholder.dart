// student_home_placeholder.dart — Parking map tab placeholder (Phase 1 — Week 3)
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';

/// Placeholder shown in the Map tab until the real parking map is built in Phase 1.
class StudentHomePlaceholder extends StatelessWidget {
  const StudentHomePlaceholder({super.key});

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
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(LucideIcons.mapPin, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Parking Map', style: AppTypography.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 1 — Week 3',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
