// points_history_screen.dart — S11: Paginated points transaction history with filter chips
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../models/points_transaction.dart';
import '../../providers/points_provider.dart';

/// S11 — Points History screen.
///
/// Displays a paginated, filterable list of the student's points transactions.
/// Supports infinite scroll and filter chips (All / Earned / Spent / Expired).
class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  late final ScrollController _scrollController;

  static const _filters = [
    (label: 'All',     value: null),
    (label: 'Earned',  value: 'EARNED'),
    (label: 'Spent',   value: 'SPENT'),
    (label: 'Expired', value: 'EXPIRED'),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PointsProvider>().loadHistory();
    });
  }

  void _onScroll() {
    final provider = context.read<PointsProvider>();
    if (provider.isLoadingMore || !provider.hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      provider.loadMoreHistory();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PointsProvider>();

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
        title: Text('Points History', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          _buildFilterRow(provider),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────────

  Widget _buildFilterRow(PointsProvider provider) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final selected = provider.selectedFilter == f.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => context.read<PointsProvider>().setFilter(f.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: selected
                          ? AppColors.background
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────────

  Widget _buildBody(PointsProvider provider) {
    // First-load skeleton
    if (provider.isLoadingHistory && provider.transactions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        children: List.generate(6, (i) => _ShimmerCard(delay: i * 60)),
      );
    }

    // Error state
    if (provider.error != null && provider.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<PointsProvider>().loadHistory(),
              child: Text(
                'Retry',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (provider.transactions.isEmpty) {
      final filter = provider.selectedFilter;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.coins,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              filter != null
                  ? 'No ${filter.toLowerCase()} transactions'
                  : 'No transactions yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Transaction list
    return ListView.builder(
      controller:  _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount:   provider.transactions.length + 1,
      itemBuilder: (_, index) {
        if (index < provider.transactions.length) {
          return _buildTransactionCard(provider.transactions[index]);
        }

        // Footer
        if (provider.isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              "You've reached the end",
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Transaction card ──────────────────────────────────────────────────────────

  Widget _buildTransactionCard(PointsTransaction tx) {
    final accentColor = _accentColor(tx.transactionType);
    final prefix      = tx.isDebit ? '−' : '+';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip
            Container(width: 4, color: accentColor),

            // Card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Points amount
                    SizedBox(
                      width: 64,
                      child: Text(
                        '$prefix${tx.absPoints}',
                        style: AppTypography.displaySmall.copyWith(
                          color:    accentColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Description + type pill
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize:       MainAxisSize.min,
                        children: [
                          Text(
                            tx.description,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tx.transactionType,
                              style: AppTypography.labelSmall.copyWith(
                                color:    accentColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Date (right-aligned)
                    Text(
                      _formatDate(tx.createdAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.right,
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

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Color _accentColor(String type) {
    switch (type) {
      case 'EARNED':  return AppColors.success;
      case 'SPENT':   return AppColors.error;
      case 'EXPIRED': return AppColors.textTertiary;
      default:        return AppColors.primary; // DIVIDED, POOLED
    }
  }

  /// Formats a [DateTime] as "Apr 18" or "Apr 18\n2025" for past years.
  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final currentYear = DateTime.now().year;
    final base = '${months[dt.month - 1]} ${dt.day}';
    return dt.year == currentYear ? base : '$base\n${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer loading card
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  final int delay;
  const _ShimmerCard({this.delay = 0});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 72,
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent strip placeholder
            Container(
              width: 4,
              color: AppColors.divider,
            ),
            // Shimmer sweep
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(_anim.value - 0.5, 0),
                  end:   Alignment(_anim.value + 0.5, 0),
                  colors: const [
                    AppColors.surfaceLight,
                    AppColors.surfaceHighlight,
                    AppColors.surfaceLight,
                  ],
                ).createShader(bounds),
                child: Container(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
