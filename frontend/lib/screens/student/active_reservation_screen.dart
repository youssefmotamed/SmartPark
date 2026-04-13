// active_reservation_screen.dart — Active reservation screen with QR and timer (S07)
// Placeholder — full implementation coming in next task
import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';

/// Placeholder for S07 — Active Reservation Screen.
/// Shows the student's current reservation with QR code and countdown timer.
class ActiveReservationScreen extends StatelessWidget {
  const ActiveReservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Your Reservation', style: AppTypography.displaySmall),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Active Reservation',
              style: AppTypography.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Full screen coming in next task',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
