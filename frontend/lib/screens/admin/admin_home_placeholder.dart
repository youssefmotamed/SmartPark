// admin_home_placeholder.dart — Admin dashboard placeholder (Phase 6)
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';

const _adminAccent = Color(0xFF9C8FFF);

/// Placeholder shown in the Dashboard tab until the real admin panel is built in Phase 6.
class AdminHomePlaceholder extends StatelessWidget {
  const AdminHomePlaceholder({super.key});

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
                color: _adminAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(LucideIcons.layoutDashboard, size: 36, color: _adminAccent),
            ),
            const SizedBox(height: 20),
            Text('Admin Dashboard', style: AppTypography.displaySmall),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 6',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
