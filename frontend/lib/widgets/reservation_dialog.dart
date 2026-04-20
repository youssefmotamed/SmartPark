// reservation_dialog.dart — S06: Reservation confirmation dialog with badge selector and leave time picker
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/spot.dart';
import '../../models/badge_summary.dart';
import '../../models/create_reservation_request.dart';
import '../../providers/badge_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../services/profile_service.dart';
import 'error_dialog.dart';

/// Bottom sheet that selects a badge, optionally uses an advance reservation
/// token, picks leave time, and confirms a reservation.
///
/// Opens via [SpotDetailSheet] after the student taps "RESERVE THIS SPOT".
/// On success, navigates to /student/reservation.
class ReservationDialog extends StatefulWidget {
  final Spot spot;

  const ReservationDialog({
    super.key,
    required this.spot,
  });

  @override
  State<ReservationDialog> createState() => _ReservationDialogState();
}

class _ReservationDialogState extends State<ReservationDialog> {
  // ── Badge data ────────────────────────────────────────────────────────────
  List<BadgeSummary> _badges        = [];
  BadgeSummary?      _selectedBadge;
  bool               _loadingBadges = true;

  // ── Advance token ─────────────────────────────────────────────────────────
  bool _useAdvanceToken = false;

  // ── Leave time ────────────────────────────────────────────────────────────
  late DateTime _expectedLeaveTime;
  bool          _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _expectedLeaveTime = DateTime.now().add(const Duration(hours: 2));
    _loadData();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    await _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final all    = await ProfileService().getBadges();
      final active = all.where((b) => b.isActive).toList();
      if (!mounted) return;
      // Pre-select the user's default badge if it's in the active list.
      final defaultBadge = context.read<BadgeProvider>().defaultBadge;
      final preselect = (defaultBadge != null &&
              active.any((b) => b.badgeId == defaultBadge.badgeId))
          ? active.firstWhere((b) => b.badgeId == defaultBadge.badgeId)
          : active.firstOrNull;
      setState(() {
        _badges        = active;
        _selectedBadge = preselect;
        _loadingBadges = false;
      });
      // Restore token badge ID from redemption history if lost on app restart.
      final rewardsProvider = context.read<RewardsProvider>();
      if (rewardsProvider.advanceTokenBadgeId == null && preselect != null) {
        rewardsProvider.restoreUnusedToken(preselect.badgeId);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBadges = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _badgeDisplayName(String type) {
    switch (type) {
      case 'CARPOOL_2': return 'Carpool 2';
      case 'CARPOOL_3': return 'Carpool 3';
      case 'CARPOOL_4': return 'Carpool 4';
      case 'CARPOOL_5': return 'Carpool 5';
      default:          return 'Individual';
    }
  }

  Color _tierColor(String type) {
    switch (type) {
      case 'CARPOOL_2': return AppColors.carpool2;
      case 'CARPOOL_3': return AppColors.carpool3;
      case 'CARPOOL_4': return AppColors.carpool4;
      case 'CARPOOL_5': return AppColors.carpool5;
      default:          return AppColors.individual;
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

  /// True only when a token exists AND it was purchased by the selected badge.
  bool get _hasAdvanceToken {
    final tokenBadgeId = context.read<RewardsProvider>().advanceTokenBadgeId;
    if (tokenBadgeId == null || _selectedBadge == null) return false;
    return tokenBadgeId == _selectedBadge!.badgeId;
  }

  /// True when any token exists, regardless of which badge owns it.
  bool get _hasAnyToken =>
      context.read<RewardsProvider>().advanceTokenBadgeId != null;

  // ── Badge picker sheet ────────────────────────────────────────────────────

  void _showBadgePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BadgePickerSheet(
        badges:   _badges,
        selected: _selectedBadge,
        onSelect: (b) {
          setState(() {
            _selectedBadge   = b;
            _useAdvanceToken = false;
          });
          Navigator.pop(context);
        },
        tierColor:        _tierColor,
        badgeDisplayName: _badgeDisplayName,
      ),
    );
  }

  // ── Time picker ───────────────────────────────────────────────────────────

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
                      child: Text('Cancel',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                    Text('Leave Time', style: AppTypography.labelMedium),
                    TextButton(
                      onPressed: () {
                        setState(() => _expectedLeaveTime = tempTime);
                        Navigator.pop(context);
                      },
                      child: Text('Done',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.primary)),
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

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitReservation() async {
    if (_selectedBadge == null) return;
    setState(() => _isSubmitting = true);

    final bool success;
    if (_useAdvanceToken && _hasAdvanceToken) {
      success = await context.read<ReservationProvider>().createAdvanceReservation(
        spotId:            widget.spot.id,
        badgeId:           _selectedBadge!.badgeId,
        expectedLeaveTime: _expectedLeaveTime,
      );
    } else {
      final request = CreateReservationRequest(
        spotId:            widget.spot.id,
        badgeId:           _selectedBadge!.badgeId,
        expectedLeaveTime: _expectedLeaveTime,
        latitude:          null,
        longitude:         null,
      );
      success = await context.read<ReservationProvider>().createReservation(request);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      context.go('/student/reservation');
    } else {
      final error = context.read<ReservationProvider>().createError
          ?? 'Failed to create reservation';
      showErrorDialog(context, title: 'Reservation Failed', message: error);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            // Drag handle
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

            const SizedBox(height: 20),

            // Title + subtitle
            Text('Reserve Spot', style: AppTypography.displaySmall),
            const SizedBox(height: 4),
            Text(
              '${widget.spot.spotLabel} — ${_zoneName(widget.spot.zoneCode)}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Summary card
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
                  _infoRow('Timer', '15 min to reach gate'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Badge selector
            Text('Badge', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            _buildBadgeSelector(),

            const SizedBox(height: 16),

            // Advance token toggle
            _buildAdvanceTokenRow(),

            const SizedBox(height: 20),

            // Leave time label + picker
            Text('Expected Leave Time', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
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
                    const Icon(LucideIcons.clock, size: 18,
                        color: AppColors.textTertiary),
                    const SizedBox(width: 12),
                    Text(_formatTime(_expectedLeaveTime),
                        style: AppTypography.bodyLarge),
                    const Spacer(),
                    const Icon(LucideIcons.chevronDown, size: 18,
                        color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Confirm button
            GestureDetector(
              onTap: (_isSubmitting || _selectedBadge == null)
                  ? null
                  : _submitReservation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: (_isSubmitting || _selectedBadge == null)
                      ? AppColors.primary.withValues(alpha: 0.5)
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
                        _useAdvanceToken && _hasAdvanceToken
                            ? 'CONFIRM (ADVANCE RESERVATION)'
                            : 'CONFIRM RESERVATION',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.background,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Badge selector widget ─────────────────────────────────────────────────

  Widget _buildBadgeSelector() {
    if (_loadingBadges) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    if (_badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Text(
          'No active badges — create one first',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    // Single badge — non-tappable display row
    if (_badges.length == 1) {
      final b = _badges.first;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Row(
          children: [
            _BadgeDot(color: _tierColor(b.badgeType)),
            const SizedBox(width: 12),
            Text(_badgeDisplayName(b.badgeType),
                style: AppTypography.bodyMedium),
            const SizedBox(width: 8),
            Text('#${b.badgeId}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary)),
          ],
        ),
      );
    }

    // Multiple badges — tappable selector
    return GestureDetector(
      onTap: _showBadgePicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Row(
          children: [
            if (_selectedBadge != null) ...[
              _BadgeDot(color: _tierColor(_selectedBadge!.badgeType)),
              const SizedBox(width: 12),
              Text(_badgeDisplayName(_selectedBadge!.badgeType),
                  style: AppTypography.bodyMedium),
              const SizedBox(width: 8),
              Text('#${_selectedBadge!.badgeId}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiary)),
            ] else
              Text('Select a badge',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textTertiary)),
            const Spacer(),
            const Icon(LucideIcons.chevronDown, size: 18,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  // ── Advance token row ─────────────────────────────────────────────────────

  Widget _buildAdvanceTokenRow() {
    // Watch so the row rebuilds when RewardsProvider changes.
    final tokenBadgeId    = context.watch<RewardsProvider>().advanceTokenBadgeId;
    final hasMatchingToken = _hasAdvanceToken;
    final hasAnyToken      = _hasAnyToken;

    // ── State 1: no token at all ──────────────────────────────────────────
    if (!hasAnyToken) {
      return Opacity(
        opacity: 0.4,
        child: _tokenContainer(
          borderColor: AppColors.divider,
          icon: LucideIcons.zap,
          iconColor: AppColors.textTertiary,
          subtitle: 'No token available — redeem one from Rewards Store',
          subtitleColor: AppColors.textTertiary,
          switchValue: false,
          switchEnabled: false,
        ),
      );
    }

    // ── State 2: token exists but for a different badge ───────────────────
    if (!hasMatchingToken) {
      final tokenBadge = context.read<BadgeProvider>().badges
          .where((b) => b.badgeId == tokenBadgeId)
          .firstOrNull;
      final badgeName = tokenBadge != null
          ? _badgeDisplayName(tokenBadge.badgeType)
          : 'another badge';
      return _tokenContainer(
        borderColor: AppColors.warning.withValues(alpha: 0.4),
        icon: LucideIcons.alertCircle,
        iconColor: AppColors.warning,
        subtitle: 'Token belongs to $badgeName — switch badges to use it',
        subtitleColor: AppColors.warning,
        switchValue: false,
        switchEnabled: false,
      );
    }

    // ── State 3: token matches selected badge — fully interactive ─────────
    return _tokenContainer(
      borderColor: _useAdvanceToken
          ? AppColors.primary.withValues(alpha: 0.4)
          : AppColors.divider,
      icon: LucideIcons.zap,
      iconColor: AppColors.primary,
      subtitle: 'Geolocation bypassed for this reservation',
      subtitleColor: AppColors.textSecondary,
      switchValue: _useAdvanceToken,
      switchEnabled: true,
      onSwitchChanged: (v) => setState(() => _useAdvanceToken = v),
    );
  }

  Widget _tokenContainer({
    required Color     borderColor,
    required IconData  icon,
    required Color     iconColor,
    required String    subtitle,
    required Color     subtitleColor,
    required bool      switchValue,
    required bool      switchEnabled,
    ValueChanged<bool>? onSwitchChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Use Advance Reservation Token',
                    style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.bodySmall
                        .copyWith(color: subtitleColor)),
              ],
            ),
          ),
          Switch(
            value: switchValue,
            onChanged: switchEnabled ? onSwitchChanged : null,
            activeThumbColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceHighlight,
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiary)),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BadgePickerSheet extends StatelessWidget {
  final List<BadgeSummary>           badges;
  final BadgeSummary?                selected;
  final ValueChanged<BadgeSummary>   onSelect;
  final Color Function(String type)  tierColor;
  final String Function(String type) badgeDisplayName;

  const _BadgePickerSheet({
    required this.badges,
    required this.selected,
    required this.onSelect,
    required this.tierColor,
    required this.badgeDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Select Badge', style: AppTypography.displaySmall),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: badges.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final b          = badges[i];
            final isSelected = selected?.badgeId == b.badgeId;
            return GestureDetector(
              onTap: () => onSelect(b),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.divider,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    _BadgeDot(color: tierColor(b.badgeType)),
                    const SizedBox(width: 12),
                    Text(badgeDisplayName(b.badgeType),
                        style: AppTypography.bodyMedium),
                    const SizedBox(width: 8),
                    Text('#${b.badgeId}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textTertiary)),
                    const Spacer(),
                    if (isSelected)
                      const Icon(LucideIcons.check,
                          size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Tiny colored dot for badge tier ──────────────────────────────────────────

class _BadgeDot extends StatelessWidget {
  final Color color;
  const _BadgeDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
