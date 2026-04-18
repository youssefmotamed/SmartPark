// spot_detail_sheet.dart — S05: Spot detail bottom sheet, gateway to reservation flow
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/app_spacing.dart';
import '../../config/app_typography.dart';
import '../../models/spot.dart';
import '../../services/profile_service.dart';
import 'reservation_dialog.dart';

/// Bottom sheet displayed when a student taps an available parking spot.
///
/// Fetches badge info on open, then gates the Reserve button accordingly.
class SpotDetailSheet extends StatefulWidget {
  final Spot spot;
  final bool isTooFar;
  final bool isAdvanceReservation;

  const SpotDetailSheet({
    super.key,
    required this.spot,
    required this.isTooFar,
    this.isAdvanceReservation = false,
  });

  @override
  State<SpotDetailSheet> createState() => _SpotDetailSheetState();
}

class _SpotDetailSheetState extends State<SpotDetailSheet> {
  bool    _isLoadingBadge = true;
  int?    _badgeId;
  String? _badgeType;
  String? _badgeError;

  @override
  void initState() {
    super.initState();
    _loadBadgeInfo();
  }

  Future<void> _loadBadgeInfo() async {
    setState(() => _isLoadingBadge = true);
    try {
      final profile = await ProfileService().getProfile();
      if (mounted) {
        setState(() {
          _badgeId    = profile.activeBadge?.id;
          _badgeType  = profile.activeBadge?.type;
          _badgeError = profile.activeBadge == null
              ? 'No active badge found'
              : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _badgeError = 'Failed to load badge info');
    } finally {
      if (mounted) setState(() => _isLoadingBadge = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _badgeDisplayName(String? type) {
    switch (type) {
      case 'CARPOOL_2': return 'Carpool 2 Badge';
      case 'CARPOOL_3': return 'Carpool 3 Badge';
      case 'CARPOOL_4': return 'Carpool 4 Badge';
      case 'CARPOOL_5': return 'Carpool 5 Badge';
      default:          return 'Individual Badge';
    }
  }

  String _accessText(String zoneCode) {
    switch (zoneCode) {
      case 'A': return 'Open to all badge types';
      case 'B': return 'Carpool badges only';
      case 'C': return 'Security managed';
      default:  return 'Unknown access type';
    }
  }

  String? _disabledReason() {
    if (!widget.isAdvanceReservation && widget.isTooFar) {
      return 'Move closer to campus to reserve';
    }
    if (_isLoadingBadge) return null;
    if (_badgeError != null) return 'Badge required to reserve';
    if (_badgeId == null) return 'No active badge found';
    return null;
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  void _onReserveTapped() {
    Navigator.pop(context); // Close S05
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ReservationDialog(
        spot:                 widget.spot,
        badgeId:              _badgeId!,
        badgeType:            _badgeType ?? 'INDIVIDUAL',
        isAdvanceReservation: widget.isAdvanceReservation,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + 20;
    final isDisabled = _disabledReason() != null || _isLoadingBadge;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 40 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.bottomSheetRadius),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
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

            // 3. Spot header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spot ${widget.spot.spotLabel}',
                      style: AppTypography.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.spot.zoneName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildStatusPill(),
              ],
            ),

            // 4.
            const SizedBox(height: 20),

            // 5. Divider
            const Divider(color: AppColors.divider, height: 1),

            // 6.
            const SizedBox(height: 16),

            // 7. Access row
            Row(
              children: [
                const Icon(LucideIcons.info, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Text(_accessText(widget.spot.zoneCode), style: AppTypography.bodyMedium),
              ],
            ),

            // 8.
            const SizedBox(height: 16),

            // 9. Badge info row
            _buildBadgeRow(),

            // 10.
            const SizedBox(height: 24),

            // 11. Reserve button
            GestureDetector(
              onTap: isDisabled ? null : _onReserveTapped,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  'RESERVE THIS SPOT',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.background,
                  ),
                ),
              ),
            ),

            // 12. Disabled reason text
            if (_disabledReason() != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    _disabledReason()!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────────

  Widget _buildStatusPill() {
    final color = widget.spot.statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            widget.spot.status,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeRow() {
    if (_isLoadingBadge) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text('Loading badge...', style: AppTypography.bodySmall),
        ],
      );
    }
    if (_badgeError != null) {
      return Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Text(
            _badgeError!,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(LucideIcons.creditCard, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(_badgeDisplayName(_badgeType), style: AppTypography.bodyMedium),
      ],
    );
  }
}
