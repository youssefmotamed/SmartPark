// rewards_management_screen.dart — S33: Admin reward configuration.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../providers/admin_provider.dart';
import '../../services/rewards_service.dart';

/// S33 — Rewards Management screen.
///
/// MVP has exactly one reward (Advance Reservation, seeded id=1).
/// Defaults are set immediately in [initState] so the form is always usable.
/// [_loadReward] tries to fetch real values from GET /rewards — if the
/// endpoint rejects the admin token (403) the error is swallowed silently
/// and the seeded defaults remain.  Saving always uses PUT /admin/rewards/1.
class RewardsManagementScreen extends StatefulWidget {
  const RewardsManagementScreen({super.key});

  @override
  State<RewardsManagementScreen> createState() =>
      _RewardsManagementScreenState();
}

class _RewardsManagementScreenState extends State<RewardsManagementScreen> {
  // MVP seed values — always safe to show
  int    _rewardId       = 1;
  bool   _isActive       = true;
  String _rewardName     = 'Advance Reservation';
  String _description    = 'Skip the geolocation gate and reserve in advance.';
  final  TextEditingController _costController =
      TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    // Form is immediately usable with seed defaults.
    // _loadReward runs in background and updates if it succeeds.
    _loadReward();
  }

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  Future<void> _loadReward() async {
    // GET /rewards is a student endpoint; admin token may get 403.
    // Catch everything silently so the fallback defaults always show.
    try {
      final rewards = await RewardsService().getRewards();
      if (rewards.isNotEmpty && mounted) {
        final r = rewards.first;
        setState(() {
          _rewardId    = r.id;
          _isActive    = r.active;
          _rewardName  = r.rewardName;
          _description = r.description;
          _costController.text = r.pointsCost.toString();
        });
      }
    } catch (_) {
      // Silently keep MVP defaults — PUT /admin/rewards/1 still works.
    }
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
      _rewardId,
      pointsCost: cost,
      isActive:   _isActive,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_rewardName updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.operationError ?? 'Update failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<AdminProvider>().isOperating;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width:  48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:        AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.gift,
                        size: 24, color: AppColors.success),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_rewardName, style: AppTypography.bodyLarge),
                        const SizedBox(height: 2),
                        Text(
                          _description,
                          style: AppTypography.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Points cost ─────────────────────────────────────────────────
            Text('Points Cost',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller:   _costController,
              keyboardType: TextInputType.number,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled:     true,
                fillColor:  AppColors.surfaceLight,
                hintText:   'e.g. 50',
                hintStyle:  AppTypography.bodySmall,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                suffixText:  'pts',
                suffixStyle: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),

            const SizedBox(height: 20),

            // ── Active toggle ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:        AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.toggleRight,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reward Active',
                            style: AppTypography.bodyMedium),
                        Text(
                          _isActive
                              ? 'Students can redeem this reward'
                              : 'Reward is hidden from students',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value:            _isActive,
                    onChanged:        (v) => setState(() => _isActive = v),
                    activeThumbColor: AppColors.primary,
                    inactiveThumbColor: AppColors.textTertiary,
                    inactiveTrackColor: AppColors.divider,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: AppSpacing.buttonHeight,
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
                        width:  18,
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
      ),
    );
  }
}
