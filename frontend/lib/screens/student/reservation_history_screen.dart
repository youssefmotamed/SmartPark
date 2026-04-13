// reservation_history_screen.dart — S08: Reservation history with active + past sections
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

/// S08 — Reservation History screen.
///
/// Shows two sections:
/// - **Active** (ACTIVE / ENTERED): current reservation card, taps to S07.
/// - **Past** (COMPLETED / EXPIRED / CANCELLED): filterable, paginated list.
///   Each card is tappable to view its QR code in a bottom sheet.
class ReservationHistoryScreen extends StatefulWidget {
  const ReservationHistoryScreen({super.key});

  @override
  State<ReservationHistoryScreen> createState() =>
      _ReservationHistoryScreenState();
}

class _ReservationHistoryScreenState extends State<ReservationHistoryScreen> {
  String? _selectedFilter;
  late final ScrollController _scrollController;

  static const List<Map<String, String?>> _filters = [
    {'label': 'All',       'value': null},
    {'label': 'Completed', 'value': 'COMPLETED'},
    {'label': 'Expired',   'value': 'EXPIRED'},
    {'label': 'Cancelled', 'value': 'CANCELLED'},
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReservationProvider>();
      provider.fetchActiveReservation();
      provider.fetchHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ReservationProvider>().loadMoreHistory();
    }
  }

  void _applyFilter(String? status) {
    setState(() => _selectedFilter = status);
    context.read<ReservationProvider>().fetchHistory(status: status);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildFilterRow(),
            Expanded(child: _buildContent(provider)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH, AppSpacing.screenV, AppSpacing.screenH, 0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/student/home'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Back', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Spacer(),
          Text('History', style: AppTypography.displaySmall),
        ],
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter['value'];
            return GestureDetector(
              onTap: () => _applyFilter(filter['value']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  filter['label']!,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? AppColors.background : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────────

  Widget _buildContent(ReservationProvider provider) {
    final activeRes    = provider.activeReservation;
    final hasActive    = activeRes != null;
    final history      = provider.history;
    final hasMorePages = provider.hasMorePages;

    // Full-screen loading: nothing loaded yet
    if (provider.isLoadingActive && provider.isLoadingHistory && !hasActive && history.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
        itemCount: 3,
        itemBuilder: (_, _) => const _ShimmerCard(),
      );
    }

    // Full-screen error: nothing loaded
    if (provider.historyError != null && !hasActive && history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(provider.historyError!, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ReservationProvider>().fetchActiveReservation();
                _applyFilter(_selectedFilter);
              },
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
      );
    }

    // Full-screen empty: no active, no history
    if (!hasActive && history.isEmpty && !provider.isLoadingHistory) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.parkingCircle, size: 56, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'No reservations yet',
                style: AppTypography.displaySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Your parking history will appear here',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Data view — active section + past section in one scrollable list
    return CustomScrollView(
      controller: _scrollController,
      slivers: [

        // ── Active reservation section ────────────────────────────────────────
        if (hasActive) ...[
          _sectionLabel('Active'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.md,
              ),
              child: _buildActiveCard(activeRes),
            ),
          ),
        ],

        // ── Past reservations section ─────────────────────────────────────────
        if (history.isNotEmpty || provider.isLoadingHistory)
          _sectionLabel('Past'),

        // History shimmer (loading more / initial load with active already shown)
        if (provider.isLoadingHistory && history.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, _) => const _ShimmerCard(),
                childCount: 3,
              ),
            ),
          ),

        // History items
        if (history.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, 0, AppSpacing.screenH, AppSpacing.sm,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < history.length) {
                    return _buildHistoryCard(history[index]);
                  }
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                childCount: history.length + (hasMorePages ? 1 : 0),
              ),
            ),
          ),

        // Empty past section (active exists but no history)
        if (hasActive && history.isEmpty && !provider.isLoadingHistory)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.lg,
              ),
              child: Text(
                'No past reservations',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ],
    );
  }

  /// Section label sliver (e.g. "Active", "Past").
  SliverToBoxAdapter _sectionLabel(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.sm,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }

  // ── Active reservation card ───────────────────────────────────────────────────

  Widget _buildActiveCard(ReservationResponse reservation) {
    final statusColor = AppColors.success;

    return GestureDetector(
      onTap: () => context.go('/student/reservation'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 1),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spot ${reservation.spotLabel}', style: AppTypography.labelLarge),
                            _buildStatusPill(reservation.status, statusColor),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_zoneName(reservation.zoneCode)} · ${_badgeName(reservation.badgeType)}',
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(LucideIcons.qrCode, size: 14, color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              'Tap to view QR code',
                              style: AppTypography.bodySmall.copyWith(color: statusColor),
                            ),
                            const Spacer(),
                            Icon(LucideIcons.chevronRight, size: 16, color: statusColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Past reservation card ─────────────────────────────────────────────────────

  void _showQrSheet(ReservationResponse reservation) {
    if (reservation.qrCodeData.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Spot ${reservation.spotLabel}', style: AppTypography.displaySmall),
            const SizedBox(height: 4),
            Text(
              _statusLabel(reservation.status),
              style: AppTypography.bodyMedium.copyWith(
                color: _statusColor(reservation.status),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.divider),
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
            const SizedBox(height: 12),
            Text(
              reservation.qrCodeData,
              style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ReservationResponse reservation) {
    final statusColor = _statusColor(reservation.status);

    return GestureDetector(
      onTap: () => _showQrSheet(reservation),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 1),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Spot ${reservation.spotLabel}', style: AppTypography.labelLarge),
                              _buildStatusPill(reservation.status, statusColor),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_zoneName(reservation.zoneCode)} · ${_badgeName(reservation.badgeType)}',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 6),
                              Text(_formatDateTime(reservation.reservedAt), style: AppTypography.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED': return AppColors.success;
      case 'ACTIVE':    return AppColors.success;
      case 'ENTERED':   return AppColors.success;
      case 'EXPIRED':   return AppColors.error;
      case 'CANCELLED': return AppColors.error;
      default:          return AppColors.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'COMPLETED': return 'Completed';
      case 'EXPIRED':   return 'Expired';
      case 'CANCELLED': return 'Cancelled';
      case 'ACTIVE':    return 'Active';
      case 'ENTERED':   return 'Entered';
      default:          return status;
    }
  }

  String _zoneName(String code) {
    switch (code) {
      case 'A': return 'Zone A';
      case 'B': return 'Zone B';
      case 'C': return 'Zone C';
      default:  return 'Zone $code';
    }
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

  String _formatDateTime(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour   = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $period';
  }
}

// ── Shimmer loading card ───────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        height: 88,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
    );
  }
}
