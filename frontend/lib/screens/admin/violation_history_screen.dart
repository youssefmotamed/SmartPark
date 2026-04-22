// violation_history_screen.dart — S32: Admin violation history with infinite scroll.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/admin_violation.dart';
import '../../providers/admin_provider.dart';

/// S32 — Violation History screen.
///
/// Displays a paginated list of all violations filed by guards.
/// Cards are colour-coded by violation type. Pull-to-refresh reloads.
class ViolationHistoryScreen extends StatefulWidget {
  const ViolationHistoryScreen({super.key});

  @override
  State<ViolationHistoryScreen> createState() => _ViolationHistoryScreenState();
}

class _ViolationHistoryScreenState extends State<ViolationHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadViolations();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminProvider>().loadMoreViolations();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.textSecondary),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        title: Text('Violation History', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: () {
        if (provider.isLoadingViolations && provider.violations.isEmpty) {
          return _buildLoading();
        }
        if (provider.violationsError != null && provider.violations.isEmpty) {
          return _buildError(provider);
        }
        if (provider.violations.isEmpty) {
          return _buildEmpty();
        }
        return _buildList(provider);
      }(),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(AdminProvider provider) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      onRefresh: () => context.read<AdminProvider>().loadViolations(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount:
            provider.violations.length + (provider.violationsHasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == provider.violations.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            );
          }
          return _ViolationCard(violation: provider.violations[i]);
        },
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        height: 88,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.shieldCheck,
              size: 48, color: AppColors.success),
          const SizedBox(height: 12),
          Text('No violations on record',
              style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError(AdminProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(provider.violationsError!,
                style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<AdminProvider>().loadViolations(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius)),
              ),
              child: Text('Retry',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.background)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Violation card
// ─────────────────────────────────────────────────────────────────────────────

class _ViolationCard extends StatelessWidget {
  final AdminViolation violation;

  const _ViolationCard({required this.violation});

  static (Color color, String label) _typeInfo(String type) =>
      switch (type) {
        'NO_RESERVATION' => (AppColors.error,   'No Reservation'),
        'WRONG_SPOT'     => (AppColors.warning,  'Wrong Spot'),
        'UNAUTHORIZED'   => (AppColors.error,    'Unauthorized'),
        'IDLING'         => (AppColors.info,     'Idling'),
        _                => (AppColors.textSecondary, type),
      };

  static String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _typeInfo(violation.violationType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent
            Container(width: 4, color: color),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: type pill + date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: AppTypography.labelSmall.copyWith(
                                color: color, fontSize: 10),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(violation.createdAt),
                          style: AppTypography.bodySmall
                              .copyWith(fontSize: 10),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Plate number (mono)
                    Text(
                      violation.plateNumber,
                      style: AppTypography.labelMedium.copyWith(
                          fontFamily: 'JetBrains Mono'),
                    ),

                    const SizedBox(height: 4),

                    // Details row
                    Row(
                      children: [
                        _Detail(
                          label: 'Badge #${violation.badgeId}',
                          sub:   violation.badgeType.replaceAll('_', ' '),
                        ),
                        const SizedBox(width: 16),
                        _Detail(
                          label: '${violation.suspensionDays}d suspension',
                          sub:   'by ${violation.guardName}',
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

class _Detail extends StatelessWidget {
  final String label;
  final String sub;
  const _Detail({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall),
        Text(sub,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textTertiary, fontSize: 10)),
      ],
    );
  }
}
