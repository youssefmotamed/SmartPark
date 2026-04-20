// spot_override_screen.dart — S27: Guard manually overrides a spot's status.
// Shows all spots in a grid, a status selector, a reason dropdown, and Apply.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/spot.dart';
import '../../providers/guard_provider.dart';
import '../../providers/spots_provider.dart';

/// S27 — Spot Override screen.
///
/// Guard selects a spot from the live grid, picks a new status, selects a
/// reason, then calls [GuardProvider.overrideSpotStatus]. On success the
/// spots list is refreshed and a SnackBar confirms the change.
class SpotOverrideScreen extends StatefulWidget {
  const SpotOverrideScreen({super.key});

  @override
  State<SpotOverrideScreen> createState() => _SpotOverrideScreenState();
}

class _SpotOverrideScreenState extends State<SpotOverrideScreen> {
  Spot?   _selectedSpot;
  String? _newStatus;   // 'AVAILABLE' | 'OCCUPIED' | 'UNAVAILABLE'
  String? _reason;      // OverrideReason enum value

  static const List<_StatusOption> _statusOptions = [
    _StatusOption('AVAILABLE',   'Available',   AppColors.available),
    _StatusOption('OCCUPIED',    'Occupied',    AppColors.occupied),
    _StatusOption('UNAVAILABLE', 'Unavailable', AppColors.unavailable),
  ];

  static const List<_ReasonOption> _reasonOptions = [
    _ReasonOption('CAMERA_ERROR',      'Camera Error'),
    _ReasonOption('LEFT_UNDETECTED',   'Left Undetected'),
    _ReasonOption('MAINTENANCE',       'Maintenance'),
    _ReasonOption('EVENT',             'Special Event'),
    _ReasonOption('OTHER',             'Other'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().fetchSpots();
    });
  }

  // ── Apply action ───────────────────────────────────────────────────────────

  Future<void> _handleApply() async {
    if (_selectedSpot == null || _newStatus == null || _reason == null) return;

    final guardProvider = context.read<GuardProvider>();
    final spotsProvider = context.read<SpotsProvider>();
    guardProvider.clearOperationError();

    final ok = await guardProvider.overrideSpotStatus(
      spotId:    _selectedSpot!.id,
      newStatus: _newStatus!,
      reason:    _reason!,
    );

    if (!mounted) return;

    if (ok) {
      await spotsProvider.fetchSpots();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Spot ${_selectedSpot!.spotLabel} set to $_newStatus',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _selectedSpot = null;
        _newStatus    = null;
        _reason       = null;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final guardProvider = context.watch<GuardProvider>();
    final spotsProvider = context.watch<SpotsProvider>();

    final spots = spotsProvider.spots
      ..sort((a, b) => a.spotLabel.compareTo(b.spotLabel));

    final bool canApply = _selectedSpot != null
        && _newStatus != null
        && _reason != null
        && !guardProvider.isOverridingSpot;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Spot Override', style: AppTypography.displaySmall),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => context.read<SpotsProvider>().fetchSpots(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Section: Spot grid ─────────────────────────────────────────
            Row(
              children: [
                Text('Select Spot',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                _buildLegend(),
              ],
            ),
            const SizedBox(height: 12),

            if (spotsProvider.isLoading && spots.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                      color: AppColors.warning, strokeWidth: 2),
                ),
              )
            else if (spots.isEmpty)
              _buildEmptySpots()
            else
              _buildSpotGrid(spots),

            // ── Selected spot banner ───────────────────────────────────────
            if (_selectedSpot != null) ...[
              const SizedBox(height: 20),
              _buildSelectedBanner(_selectedSpot!),
            ],

            const SizedBox(height: 24),

            // ── Section: New status ────────────────────────────────────────
            Text('New Status',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Row(
              children: _statusOptions.map((opt) {
                final isSelected = _newStatus == opt.value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _StatusCard(
                      option:     opt,
                      isSelected: isSelected,
                      onTap: () => setState(() => _newStatus = opt.value),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Section: Reason ────────────────────────────────────────────
            Text('Reason',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color:        AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButton<String>(
                value:           _reason,
                isExpanded:      true,
                underline:       const SizedBox.shrink(),
                dropdownColor:   AppColors.surfaceLight,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                hint: Text(
                  'Select a reason…',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textTertiary),
                ),
                items: _reasonOptions.map((r) {
                  return DropdownMenuItem(
                    value: r.value,
                    child: Text(r.label),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _reason = v),
              ),
            ),

            const SizedBox(height: 32),

            // ── Apply button ───────────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: canApply ? _handleApply : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:         AppColors.warning,
                  disabledBackgroundColor: AppColors.divider,
                  foregroundColor:         AppColors.background,
                  elevation:               0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: guardProvider.isOverridingSpot
                    ? const SizedBox(
                        width:  20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color:       Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Apply Override',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.background),
                      ),
              ),
            ),

            // ── Operation error ────────────────────────────────────────────
            if (guardProvider.operationError != null) ...[
              const SizedBox(height: 12),
              _ErrorBox(message: guardProvider.operationError!),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Spot grid ──────────────────────────────────────────────────────────────

  Widget _buildSpotGrid(List<Spot> spots) {
    return GridView.builder(
      shrinkWrap:  true,
      physics:     const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   5,
        crossAxisSpacing: 8,
        mainAxisSpacing:  8,
        childAspectRatio: 1.2,
      ),
      itemCount: spots.length,
      itemBuilder: (_, i) {
        final spot       = spots[i];
        final isSelected = _selectedSpot?.id == spot.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedSpot = spot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? spot.statusColor.withValues(alpha: 0.25)
                  : spot.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? spot.statusColor : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                spot.spotLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? spot.statusColor
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Selected spot banner ───────────────────────────────────────────────────

  Widget _buildSelectedBanner(Spot spot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: spot.statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        border: Border.all(color: spot.statusColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.mapPin, size: 18, color: spot.statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spot ${spot.spotLabel}',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Zone ${spot.zoneCode} · Current: ${spot.status}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedSpot = null),
            child: const Icon(LucideIcons.x,
                size: 18, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  // ── Legend ─────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Row(
      children: [
        _LegendDot(color: AppColors.available,   label: 'Free'),
        const SizedBox(width: 8),
        _LegendDot(color: AppColors.reserved,    label: 'Rsvd'),
        const SizedBox(width: 8),
        _LegendDot(color: AppColors.occupied,    label: 'Occ'),
        const SizedBox(width: 8),
        _LegendDot(color: AppColors.unavailable, label: 'N/A'),
      ],
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptySpots() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Text(
            'No spots available — try refreshing',
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _StatusOption {
  final String value;
  final String label;
  final Color  color;
  const _StatusOption(this.value, this.label, this.color);
}

class _ReasonOption {
  final String value;
  final String label;
  const _ReasonOption(this.value, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Status card
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final _StatusOption option;
  final bool          isSelected;
  final VoidCallback  onTap;

  const _StatusCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.18)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
          border: Border.all(
            color: isSelected ? option.color : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width:  10,
              height: 10,
              decoration: BoxDecoration(
                color: option.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.label,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? option.color : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend dot
// ─────────────────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiary, fontSize: 10)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error box
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius:
            BorderRadius.circular(AppSpacing.cardRadiusSmall),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
