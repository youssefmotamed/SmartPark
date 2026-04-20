// active_reservations_screen.dart — S24: Combined active reservations and
// guest parking list for the guard. Two tabs: student reservations and
// guard-created guest entries.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/guard_entry.dart';
import '../../providers/guard_provider.dart';

/// S24 — Active Entries screen.
///
/// Shows two tabs:
/// - Reservations: active student reservations currently on campus
/// - Guest Parking: guard-created guest slots for Zone C
///
/// Loads [GuardProvider.loadEntries] on open and supports pull-to-refresh.
class ActiveReservationsScreen extends StatefulWidget {
  const ActiveReservationsScreen({super.key});

  @override
  State<ActiveReservationsScreen> createState() =>
      _ActiveReservationsScreenState();
}

class _ActiveReservationsScreenState extends State<ActiveReservationsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuardProvider>().loadEntries();
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _badgeName(String? type) {
    switch (type) {
      case 'CARPOOL_2': return 'Carpool 2';
      case 'CARPOOL_3': return 'Carpool 3';
      case 'CARPOOL_4': return 'Carpool 4';
      case 'CARPOOL_5': return 'Carpool 5';
      default:          return 'Individual';
    }
  }

  // ── Complete guest action ─────────────────────────────────────────────────

  Future<void> _handleCompleteGuest(int guestParkingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        title: Text('Complete Guest Parking',
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textPrimary, fontSize: 16)),
        content: Text('Mark this guest as departed?',
            style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadiusSmall),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Complete',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.background)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success =
        await context.read<GuardProvider>().completeGuestParking(guestParkingId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Guest parking completed'
              : (context.read<GuardProvider>().operationError ?? 'Failed'),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider     = context.watch<GuardProvider>();
    final reservations = provider.reservations;
    final guestEntries = provider.guestEntries;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text('Active Entries', style: AppTypography.displaySmall),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw,
                  size: 20, color: AppColors.textSecondary),
              onPressed: provider.loadEntries,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: TabBar(
                indicatorColor: AppColors.warning,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.warning,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: AppTypography.labelSmall
                    .copyWith(color: AppColors.warning),
                unselectedLabelStyle: AppTypography.labelSmall
                    .copyWith(color: AppColors.textTertiary),
                tabs: [
                  Tab(text: 'Reservations (${reservations.length})'),
                  Tab(text: 'Guest (${guestEntries.length})'),
                ],
              ),
            ),
          ),
        ),
        body: () {
          if (provider.isLoadingEntries && provider.entries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.warning),
            );
          }
          if (provider.entriesError != null && provider.entries.isEmpty) {
            return _buildError(provider);
          }
          return TabBarView(
            children: [
              _buildReservationsTab(provider, reservations),
              _buildGuestTab(provider, guestEntries),
            ],
          );
        }(),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError(GuardProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.entriesError!,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: provider.loadEntries,
              child: Text(
                'Retry',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Reservations ───────────────────────────────────────────────────

  Widget _buildReservationsTab(
      GuardProvider provider, List<GuardEntry> reservations) {
    return RefreshIndicator(
      onRefresh: provider.loadEntries,
      color: AppColors.warning,
      backgroundColor: AppColors.surfaceLight,
      child: reservations.isEmpty
          ? _buildEmptyState('No active reservations')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.screenV,
                AppSpacing.screenH,
                AppSpacing.lg,
              ),
              itemCount: reservations.length,
              itemBuilder: (_, i) =>
                  _ReservationCard(
                    entry: reservations[i],
                    formatTime: _formatTime,
                    badgeName: _badgeName,
                  ),
            ),
    );
  }

  // ── Tab 2: Guest parking ──────────────────────────────────────────────────

  Widget _buildGuestTab(
      GuardProvider provider, List<GuardEntry> guestEntries) {
    return RefreshIndicator(
      onRefresh: provider.loadEntries,
      color: AppColors.warning,
      backgroundColor: AppColors.surfaceLight,
      child: guestEntries.isEmpty
          ? _buildEmptyState('No guest parking active')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.screenV,
                AppSpacing.screenH,
                AppSpacing.lg,
              ),
              itemCount: guestEntries.length,
              itemBuilder: (_, i) => _GuestCard(
                entry: guestEntries[i],
                formatTime: _formatTime,
                onComplete: _handleCompleteGuest,
              ),
            ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState(String message) {
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.parkingCircle,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reservation entry card
// ─────────────────────────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final GuardEntry entry;
  final String Function(DateTime?) formatTime;
  final String Function(String?) badgeName;

  const _ReservationCard({
    required this.entry,
    required this.formatTime,
    required this.badgeName,
  });

  @override
  Widget build(BuildContext context) {
    final isEntered   = entry.status == 'ENTERED';
    final accentColor = isEntered ? AppColors.success : AppColors.reserved;
    final statusColor = isEntered ? AppColors.success : AppColors.reserved;
    final plates      = entry.plateNumbers ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent
            Container(width: 4, color: accentColor),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: spot + status pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          entry.spotLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        _StatusPill(
                          label: entry.status ?? 'ACTIVE',
                          color: statusColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Middle row: student name + badge type
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.user,
                            size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.studentName ?? '--',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                        Text(
                          badgeName(entry.badgeType),
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),

                    // Plates row
                    if (plates.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.car,
                              size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              plates.join(' · '),
                              style: AppTypography.mono.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Bottom row: reserved time + leave time
                    Row(
                      children: [
                        const Icon(LucideIcons.clock,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Reserved ${formatTime(entry.reservedAt)}',
                          style: AppTypography.bodySmall,
                        ),
                        if (entry.expectedLeaveTime != null) ...[
                          const Spacer(),
                          Text(
                            'Leave by ${formatTime(entry.expectedLeaveTime)}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guest parking entry card
// ─────────────────────────────────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  final GuardEntry entry;
  final String Function(DateTime?) formatTime;
  final void Function(int) onComplete;

  const _GuestCard({
    required this.entry,
    required this.formatTime,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent — info blue
            Container(width: 4, color: AppColors.info),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: spot + GUEST pill
                    Row(
                      children: [
                        Text(
                          entry.spotLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'GUEST',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.info),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Plate row
                    Row(
                      children: [
                        const Icon(LucideIcons.car,
                            size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Text(
                          entry.guestPlateNumber ?? '--',
                          style: AppTypography.mono.copyWith(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // Purpose row (optional)
                    if (entry.purpose != null && entry.purpose!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.info,
                              size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.purpose!,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Bottom row: created time + Complete button
                    Row(
                      children: [
                        Text(
                          'Created ${formatTime(entry.createdAt)}',
                          style: AppTypography.bodySmall,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => onComplete(entry.id),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Complete',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color  color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}
