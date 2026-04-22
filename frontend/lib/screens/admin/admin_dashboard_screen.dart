// admin_dashboard_screen.dart — S28: Admin analytics dashboard.
// Embedded in AdminShell's IndexedStack tab 0 (no AppBar — shell provides header).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/analytics_summary.dart';
import '../../providers/admin_provider.dart';

/// S28 — Admin Dashboard.
///
/// Shows real-time campus stats (occupancy, reservations, violations, badges),
/// a system overview row, and quick-action cards for all management sections.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAnalytics();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: () {
        if (provider.isLoadingAnalytics && provider.analytics == null) {
          return _buildLoading();
        }
        if (provider.analyticsError != null && provider.analytics == null) {
          return _buildError(provider);
        }
        return _buildContent(provider.analytics!);
      }(),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(4, (_) => _buildSkeletonCard()),
          ),
          const SizedBox(height: 12),
          _buildSkeletonRow(),
          const SizedBox(height: 24),
          _buildSkeletonSection(),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 28, width: 72,
                    decoration: BoxDecoration(color: AppColors.divider,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(height: 12, width: 56,
                    decoration: BoxDecoration(color: AppColors.divider,
                        borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildSkeletonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 14, width: 100,
            decoration: BoxDecoration(color: AppColors.divider,
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 12),
        ...List.generate(4, (_) => Container(
          height: 68,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
        )),
      ],
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
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(provider.analyticsError!,
                style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: provider.loadAnalytics,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text('Retry',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.background)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(AnalyticsSummary a) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with refresh
          Row(
            children: [
              Text('Overview',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.textTertiary)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<AdminProvider>().loadAnalytics(),
                child: const Icon(LucideIcons.refreshCw,
                    size: 18, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Stats grid ───────────────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Card 1: Occupancy
              _StatCard(
                accentColor: AppColors.primary,
                value: '${a.occupiedSpots + a.reservedSpots}/${a.totalSpots}',
                label: 'Spots In Use',
                bottom: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: a.occupancyRate / 100,
                    minHeight: 4,
                    color: AppColors.primary,
                    backgroundColor: AppColors.divider,
                  ),
                ),
              ),
              // Card 2: Reservations today
              _StatCard(
                accentColor: AppColors.success,
                value: '${a.reservationsToday}',
                label: 'Reservations Today',
                trailing: const Icon(LucideIcons.calendarCheck,
                    size: 20, color: AppColors.success),
              ),
              // Card 3: Violations today
              _StatCard(
                accentColor: AppColors.error,
                value: '${a.violationsToday}',
                label: 'Violations Today',
                trailing: const Icon(LucideIcons.shieldAlert,
                    size: 20, color: AppColors.error),
              ),
              // Card 4: Active badges
              _StatCard(
                accentColor: AppColors.warning,
                value: '${a.activeBadges}',
                label: 'Active Badges',
                bottom: a.suspendedBadges > 0
                    ? Text('${a.suspendedBadges} suspended',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error))
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── System overview row ──────────────────────────────────────────
          Row(
            children: [
              _OverviewChip(value: '${a.totalStudents}', label: 'Students'),
              const SizedBox(width: 8),
              _OverviewChip(value: '${a.totalGuards}',   label: 'Guards'),
              const SizedBox(width: 8),
              _OverviewChip(
                value: '${a.availableSpots}',
                label: 'Available',
                valueColor: AppColors.success,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Quick actions ────────────────────────────────────────────────
          Text('Management',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 12),

          _ActionRow(
            icon:     LucideIcons.users,
            color:    AppColors.primary,
            title:    'User Management',
            subtitle: '${a.totalStudents + a.totalGuards} total users',
            onTap:    () => context.push('/admin/users'),
          ),
          _ActionRow(
            icon:     LucideIcons.creditCard,
            color:    AppColors.warning,
            title:    'Badge Management',
            subtitle: '${a.activeBadges} active badges',
            onTap:    () => context.push('/admin/badges'),
          ),
          _ActionRow(
            icon:     LucideIcons.shieldAlert,
            color:    AppColors.error,
            title:    'Violation History',
            subtitle: '${a.violationsToday} today',
            onTap:    () => context.push('/admin/violations'),
          ),
          _ActionRow(
            icon:     LucideIcons.gift,
            color:    AppColors.success,
            title:    'Rewards Management',
            subtitle: 'Configure advance reservation',
            onTap:    () => context.push('/admin/rewards'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final Color   accentColor;
  final String  value;
  final String  label;
  final Widget? trailing;
  final Widget? bottom;

  const _StatCard({
    required this.accentColor,
    required this.value,
    required this.label,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: accentColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: AppTypography.displayMedium
                              .copyWith(color: accentColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: AppTypography.bodySmall),
                  if (bottom != null) ...[
                    const SizedBox(height: 8),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview chip
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewChip extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _OverviewChip({
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:        AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTypography.labelLarge.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action row
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
