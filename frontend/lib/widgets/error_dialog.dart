// error_dialog.dart — Reusable error dialog for business rule violations and access errors
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/colors.dart';
import '../config/app_typography.dart';
import '../config/app_spacing.dart';

/// Shows a styled modal error dialog.
///
/// Use this instead of SnackBars for errors that deserve user attention:
/// - Zone access violations (Zone C guard-only, Zone B carpool-only)
/// - Reservation business rule failures (badge suspended, spot taken, etc.)
///
/// Usage:
/// ```dart
/// showErrorDialog(
///   context,
///   title: 'Security Only',
///   message: 'Zone C spots are managed by security guards.',
/// );
/// ```
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _ErrorDialog(title: title, message: message),
  );
}

class _ErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const _ErrorDialog({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header strip ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardRadius),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.alertCircle,
                      size: 24,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTypography.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // ── Action ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                  child: Text('Got it', style: AppTypography.labelLarge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
