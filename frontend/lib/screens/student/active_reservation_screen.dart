// active_reservation_screen.dart — S07: Active reservation with QR code + countdown timer
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/reservation_response.dart';
import '../../providers/reservation_provider.dart';

/// S07 — Active Reservation screen.
///
/// Displays the student's current reservation with:
/// - QR code (fade+scale entrance animation) for gate scanning
/// - Countdown timer with colon blink (ACTIVE) or "Parked" state (ENTERED)
/// - Spot/zone/leave-time info row
/// - Cancel button with confirmation dialog (ACTIVE only)
///
/// Polls [ReservationProvider.fetchActiveReservation] every 30 s to detect
/// ACTIVE → ENTERED transitions. Redirects to /student/home if no active
/// reservation is found.
class ActiveReservationScreen extends StatefulWidget {
  const ActiveReservationScreen({super.key});

  @override
  State<ActiveReservationScreen> createState() => _ActiveReservationScreenState();
}

class _ActiveReservationScreenState extends State<ActiveReservationScreen>
    with TickerProviderStateMixin {

  Timer? _refreshTimer;

  late final AnimationController _qrAnimController;
  late final AnimationController _colonAnimController;
  bool _colonVisible = true;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // QR card entrance: fade + scale from 0.95 → 1.0
    _qrAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Colon blink — toggles at midpoint of a 500 ms repeat
    _colonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _colonAnimController.addListener(() {
      setState(() => _colonVisible = _colonAnimController.value > 0.5);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservation();
    });

    // Poll every 30 s for ACTIVE → ENTERED status changes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadReservation();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _qrAnimController.dispose();
    _colonAnimController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────────

  Future<void> _loadReservation() async {
    await context.read<ReservationProvider>().fetchActiveReservation();
    if (!mounted) return;
    final res = context.read<ReservationProvider>().activeReservation;
    if (res == null) {
      context.go('/student/home');
      return;
    }
    _qrAnimController.forward(from: 0);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _timerColor(Duration? remaining) {
    if (remaining == null) return AppColors.primary;
    if (remaining.inSeconds < 60)  return AppColors.error;
    if (remaining.inSeconds < 120) return AppColors.warning;
    return AppColors.primary;
  }

  String _formatTime(DateTime dt) {
    final hour   = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<ReservationProvider>();
    final reservation = provider.activeReservation;
    final remaining   = provider.timeRemaining;

    // Loading state
    if (provider.isLoadingActive && reservation == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Error state
    if (provider.activeError != null && reservation == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(provider.activeError!, style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (reservation == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.screenV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(context),
              const SizedBox(height: 20),
              _buildHeader(reservation),
              const SizedBox(height: 24),
              _buildQRCard(reservation),
              const SizedBox(height: 16),
              _buildTimerCard(reservation, remaining),
              const SizedBox(height: 16),
              _buildInfoRow(reservation),
              const SizedBox(height: 24),
              if (reservation.canCancel) _buildCancelButton(context, provider),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────────

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/student/home'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            'Back to Map',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ReservationResponse reservation) {
    final zoneName = switch (reservation.zoneCode) {
      'A' => 'Zone A — Main Parking',
      'B' => 'Zone B — Carpool Zone',
      'C' => 'Zone C — Guest Area',
      _   => 'Zone ${reservation.zoneCode}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Reservation', style: AppTypography.displayMedium),
        const SizedBox(height: 4),
        Text(
          'Spot ${reservation.spotLabel} — $zoneName',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildQRCard(ReservationResponse reservation) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _qrAnimController, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(
        opacity: _qrAnimController,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              // QR code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: reservation.qrCodeData,
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.textPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.textPrimary,
                  ),
                  backgroundColor: AppColors.surfaceLight,
                ),
              ),
              const SizedBox(height: 16),
              // QR code payload string
              Text(
                reservation.qrCodeData,
                style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCard(ReservationResponse reservation, Duration? remaining) {
    final isEntered    = reservation.isEntered;
    final timerColor   = isEntered ? AppColors.success : _timerColor(remaining);
    final contextText  = isEntered ? 'Park in your spot' : 'Get to the gate!';
    final contextColor = isEntered ? AppColors.success : AppColors.warning;

    // Timer display string
    String timerText;
    if (isEntered) {
      timerText = 'Parked';
    } else if (remaining != null) {
      final mins  = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final secs  = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      final colon = _colonVisible ? ':' : ' ';
      timerText = '$mins$colon$secs';
    } else {
      timerText = '--:--';
    }

    // Progress value — 0.0 (expired) to 1.0 (full) over 15-minute window
    double progress = 1.0;
    if (!isEntered && remaining != null) {
      const totalSeconds = 15 * 60;
      progress = (remaining.inSeconds / totalSeconds).clamp(0.0, 1.0);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceHighlight],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Circular progress ring + timer text
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: isEntered ? 1.0 : progress,
                  strokeWidth: 4,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
              ),
              Text(
                timerText,
                style: isEntered
                    ? AppTypography.displaySmall.copyWith(color: timerColor)
                    : AppTypography.monoLarge.copyWith(color: timerColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contextText,
            style: AppTypography.bodyMedium.copyWith(color: contextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ReservationResponse reservation) {
    final statusColor = reservation.isEntered ? AppColors.success : AppColors.warning;
    final statusText  = reservation.isEntered ? 'Entered' : 'Active';

    return Column(
      children: [
        // Leave by time
        Row(
          children: [
            const Icon(LucideIcons.clock, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              'Leave by: ',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              _formatTime(reservation.expectedLeaveTime),
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Status indicator
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'Status: ',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              statusText,
              style: AppTypography.bodyMedium.copyWith(color: statusColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context, ReservationProvider provider) {
    return GestureDetector(
      onTap: provider.isCreating ? null : () => _showCancelDialog(context, provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: provider.isCreating
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.error,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: provider.isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.x, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Cancel Reservation',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.error),
                  ),
                ],
              ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ReservationProvider provider) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text('Cancel Reservation', style: AppTypography.displaySmall),
        content: Text(
          'Are you sure you want to cancel your reservation for spot '
          '${provider.activeReservation?.spotLabel}? '
          'The spot will become available to others.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Keep It',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await context.read<ReservationProvider>().cancelReservation();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Reservation cancelled',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: AppColors.surfaceLight,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadiusSmall),
                    ),
                  ),
                );
                context.go('/student/home');
              }
            },
            child: Text(
              'Cancel Reservation',
              style: AppTypography.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
