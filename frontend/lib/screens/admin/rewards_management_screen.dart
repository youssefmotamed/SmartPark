// rewards_management_screen.dart — S33: Admin reward configuration.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/reward.dart';
import '../../providers/admin_provider.dart';
import '../../services/rewards_service.dart';

/// S33 — Rewards Management screen.
///
/// Loads the rewards catalogue and lets the admin edit each reward's
/// [pointsCost] and active/inactive toggle. Changes are saved via
/// [AdminProvider.updateReward].
class RewardsManagementScreen extends StatefulWidget {
  const RewardsManagementScreen({super.key});

  @override
  State<RewardsManagementScreen> createState() =>
      _RewardsManagementScreenState();
}

class _RewardsManagementScreenState extends State<RewardsManagementScreen> {
  List<Reward> _rewards    = [];
  bool         _isLoading  = true;
  String?      _error;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
      _error     = null;
    });
    try {
      final list = await RewardsService().getRewards();
      if (mounted) setState(() => _rewards = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
        title: Text('Rewards Management', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: () {
        if (_isLoading) return _buildLoading();
        if (_error != null) return _buildError();
        if (_rewards.isEmpty) return _buildEmpty();
        return _buildList();
      }(),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      onRefresh: _loadRewards,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _rewards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _RewardCard(
          reward:    _rewards[i],
          onSaved:   _loadRewards,
        ),
      ),
    );
  }

  // ── States ─────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 3,
      itemBuilder: (_, _) => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.gift, size: 48, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text('No rewards configured'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRewards,
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
// Reward card
// ─────────────────────────────────────────────────────────────────────────────

class _RewardCard extends StatefulWidget {
  final Reward       reward;
  final VoidCallback onSaved;

  const _RewardCard({required this.reward, required this.onSaved});

  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> {
  late final TextEditingController _costController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(
        text: widget.reward.pointsCost.toString());
    _isActive = widget.reward.active;
  }

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final costText = _costController.text.trim();
    final cost     = int.tryParse(costText);
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid points cost')),
      );
      return;
    }

    final provider = context.read<AdminProvider>();
    final success  = await provider.updateReward(
      widget.reward.id,
      pointsCost: cost,
      isActive:   _isActive,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.reward.rewardName} updated'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.operationError ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<AdminProvider>().isOperating;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:        AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.gift,
                    size: 18, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.reward.rewardName,
                        style: AppTypography.bodyLarge),
                    Text(widget.reward.description,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Points cost field
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Points Cost',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        filled:     true,
                        fillColor:  AppColors.surface,
                        hintText:   'e.g. 50',
                        hintStyle:  AppTypography.bodySmall,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        suffixText: 'pts',
                        suffixStyle: AppTypography.bodySmall
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Active toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Active',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: 4),
                  Switch(
                    value:          _isActive,
                    onChanged:      (v) => setState(() => _isActive = v),
                    activeThumbColor: AppColors.primary,
                    inactiveThumbColor: AppColors.textTertiary,
                    inactiveTrackColor: AppColors.divider,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isBusy ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius)),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Save Changes',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.background)),
            ),
          ),
        ],
      ),
    );
  }
}
