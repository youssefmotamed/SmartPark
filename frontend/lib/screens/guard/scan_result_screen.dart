// scan_result_screen.dart — S23: Scan result screen shown after guard QR scan
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../providers/guard_provider.dart';

/// S23 — Scan Result screen.
///
/// Displayed immediately after [QRScannerScreen] processes a QR code.
/// Reads [GuardProvider.lastEntryResult] or [GuardProvider.lastExitResult]
/// and renders either:
/// - Valid entry: spot label, student name, badge, time remaining, plates list
/// - Valid exit:  spot label, student name, points earned
/// - Invalid:     reason message in an error container
///
/// "Scan Another" clears results and returns to /guard/scanner.
class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _formatSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds  % 60).toString().padLeft(2, '0');
    return '$m:$s remaining';
  }

  String _badgeName(String type) {
    switch (type) {
      case 'CARPOOL_2': return 'Carpool 2';
      case 'CARPOOL_3': return 'Carpool 3';
      case 'CARPOOL_4': return 'Carpool 4';
      case 'CARPOOL_5': return 'Carpool 5';
      default:          return 'Individual';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<GuardProvider>();
    final entryResult = provider.lastEntryResult;
    final exitResult  = provider.lastExitResult;

    final isEntry = entryResult != null;
    final isExit  = exitResult  != null;

    final bool isValid;
    if (isEntry) {
      isValid = entryResult.valid;
    } else if (isExit) {
      isValid = exitResult.exitRecorded;
    } else {
      isValid = false;
    }

    final resultColor = isValid ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header with gradient ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [
                    resultColor.withValues(alpha: 0.15),
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _animController,
                      curve:  Curves.elasticOut,
                    ),
                    child: FadeTransition(
                      opacity: _animController,
                      child: Icon(
                        isValid ? LucideIcons.checkCircle : LucideIcons.xCircle,
                        size:  72,
                        color: resultColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isValid
                        ? (isEntry ? 'Entry Approved' : 'Exit Recorded')
                        : (isEntry ? 'Entry Denied'   : 'Exit Failed'),
                    style: AppTypography.displayMedium.copyWith(color: resultColor),
                  ),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical:   24,
                ),
                child: _buildContent(
                  provider:    provider,
                  entryResult: entryResult,
                  exitResult:  exitResult,
                  isEntry:     isEntry,
                  isExit:      isExit,
                  isValid:     isValid,
                ),
              ),
            ),

            // ── Scan Another button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width:  double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<GuardProvider>().clearResults();
                    context.go('/guard/scanner');
                  },
                  icon:  const Icon(LucideIcons.qrCode, size: 18),
                  label: const Text('Scan Another'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    elevation:       0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    textStyle: AppTypography.labelLarge.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content builder ──────────────────────────────────────────────────────────

  Widget _buildContent({
    required GuardProvider provider,
    required dynamic entryResult,
    required dynamic exitResult,
    required bool isEntry,
    required bool isExit,
    required bool isValid,
  }) {
    // Network / scan error
    if (provider.scanError != null) {
      return _buildErrorBox(provider.scanError!);
    }

    // Valid entry
    if (isEntry && isValid) {
      return _buildValidEntry(entryResult);
    }

    // Invalid entry
    if (isEntry && !isValid) {
      return _buildErrorBox(
        entryResult?.reason ?? 'Invalid QR code. Reservation not found or expired.',
      );
    }

    // Valid exit
    if (isExit && isValid) {
      return _buildValidExit(exitResult);
    }

    // Invalid exit
    if (isExit && !isValid) {
      return _buildErrorBox('Exit could not be recorded. Please try again.');
    }

    // Fallback — no result data
    return _buildErrorBox('No scan data available. Please try again.');
  }

  Widget _buildValidEntry(dynamic entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Spot',           entry.spotLabel    ?? '--'),
        _infoRow('Student',        entry.studentName  ?? '--'),
        _infoRow('Badge',          _badgeName(entry.badgeType ?? '')),
        _infoRow('Time Remaining', _formatSeconds(entry.timeRemainingSeconds ?? 0)),

        const SizedBox(height: 20),

        Text(
          'Registered Plates',
          style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),

        if ((entry.registeredPlates as List).isEmpty)
          Text(
            'No plates on file',
            style: AppTypography.bodyMedium,
          )
        else
          for (final plate in entry.registeredPlates as List<String>)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:        AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                border:       Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.car, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 12),
                  Text(plate, style: AppTypography.mono),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildValidExit(dynamic exit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Spot',         exit.spotLabel   ?? '--'),
        _infoRow('Student',      exit.studentName ?? '--'),
        _infoRow('Points Earned', '${exit.pointsEarned} pts'),

        if ((exit.pointsEarned as int) == 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
            ),
            child: Text(
              'Points will be calculated in Phase 4',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertCircle, size: 20, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info row ─────────────────────────────────────────────────────────────────

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}
