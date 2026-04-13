// reservation_dialog.dart — S06: Reservation confirmation dialog with leave time picker
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/spot.dart';
import '../../models/create_reservation_request.dart';
import '../../providers/reservation_provider.dart';
import 'error_dialog.dart';

/// Bottom sheet that collects leave time and confirms a reservation.
///
/// Opened by [SpotDetailSheet] after the student taps "RESERVE THIS SPOT".
/// On success, navigates to /student/reservation.
class ReservationDialog extends StatefulWidget {
  final Spot   spot;
  final int    badgeId;
  final String badgeType;

  const ReservationDialog({
    super.key,
    required this.spot,
    required this.badgeId,
    required this.badgeType,
  });

  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  late DateTime _expectedLeaveTime;
  bool          _isSubmitting = false;
  Position?     _position;

  @override
  void initState() {
    super.initState();
    _expectedLeaveTime = DateTime.now().add(const Duration(hours: 2));
    _fetchPosition();
  }

  Future<void> _fetchPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) setState(() => _position = position);
    } catch (_) {
      // Position stays null — backend has geolocation disabled so this is fine
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _badgeDisplayName(String type) {
    switch (type) {
      case 'CARPOOL_2': return 'Carpool 2 Badge';
      case 'CARPOOL_3': return 'Carpool 3 Badge';
      case 'CARPOOL_4': return 'Carpool 4 Badge';
      case 'CARPOOL_5': return 'Carpool 5 Badge';
      default:          return 'Individual Badge';
    }
  }

  String _zoneName(String zoneCode) {
    switch (zoneCode) {
      case 'A': return 'Zone A — Main Parking';
      case 'B': return 'Zone B — Carpool Zone';
      case 'C': return 'Zone C — Guest Area';
      default:  return 'Zone $zoneCode';
    }
  }

  String _formatTime(DateTime dt) {
    final hour   = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // ── Time picker ───────────────────────────────────────────────────────────────

  void _showTimePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        DateTime tempTime = _expectedLeaveTime;
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text('Leave Time', style: AppTypography.labelMedium),
                    TextButton(
                      onPressed: () {
                        setState(() => _expectedLeaveTime = tempTime);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _expectedLeaveTime,
                    minimumDate: DateTime.now().add(const Duration(minutes: 30)),
                    use24hFormat: false,
                    onDateTimeChanged: (dt) => tempTime = dt,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _submitReservation() async {
    setState(() => _isSubmitting = true);

    final request = CreateReservationRequest(
      spotId:            widget.spot.id,
      badgeId:           widget.badgeId,
      expectedLeaveTime: _expectedLeaveTime,
      latitude:          _position?.latitude,
      longitude:         _position?.longitude,
    );

    final success =
        await context.read<ReservationProvider>().createReservation(request);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      context.go('/student/reservation');
    } else {
      final error = context.read<ReservationProvider>().createError
          ?? 'Failed to create reservation';
      showErrorDialog(
        context,
        title: 'Reservation Failed',
        message: error,
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 40 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + 24;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 2.
            const SizedBox(height: 20),

            // 3. Title + subtitle
            Text('Reserve Spot', style: AppTypography.displaySmall),
            const SizedBox(height: 4),
            Text(
              '${widget.spot.spotLabel} — ${_zoneName(widget.spot.zoneCode)}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            // 4.
            const SizedBox(height: 24),

            // 5. Summary card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.divider),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow('Spot', widget.spot.spotLabel),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),
                  _infoRow('Zone', _zoneName(widget.spot.zoneCode)),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),
                  _infoRow('Badge', _badgeDisplayName(widget.badgeType)),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 10),
                  _infoRow('Timer', '15 min to reach gate'),
                ],
              ),
            ),

            // 6.
            const SizedBox(height: 20),

            // 7. Leave time label
            Text('Expected Leave Time', style: AppTypography.labelMedium),
            const SizedBox(height: 8),

            // 8. Leave time tappable field
            GestureDetector(
              onTap: _showTimePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  border: Border.all(color: AppColors.divider, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 18, color: AppColors.textTertiary),
                    const SizedBox(width: 12),
                    Text(_formatTime(_expectedLeaveTime), style: AppTypography.bodyLarge),
                    const Spacer(),
                    const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),

            // 9.
            const SizedBox(height: 24),

            // 10. Confirm button
            GestureDetector(
              onTap: _isSubmitting ? null : _submitReservation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: _isSubmitting
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                alignment: Alignment.center,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.background,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'CONFIRM RESERVATION',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.background,
                        ),
                      ),
              ),
            ),

            // 11.
            const SizedBox(height: 8),

            // 12. Cancel text button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // 13.
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────────

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
        ),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }
}
