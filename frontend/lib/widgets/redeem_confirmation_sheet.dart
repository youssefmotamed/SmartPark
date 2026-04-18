// redeem_confirmation_sheet.dart — S13: Redemption confirmation bottom sheet
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/colors.dart';
import '../config/app_typography.dart';
import '../models/reward.dart';

/// S13 — Redeem Confirmation bottom sheet.
///
/// Shows a cost/balance summary and confirmation buttons before spending points.
/// The sheet manages its own loading state while [onConfirm] is executing.
class RedeemConfirmationSheet extends StatefulWidget {
  final Reward reward;
  final int currentBalance;
  final Future<void> Function() onConfirm;

  const RedeemConfirmationSheet({
    super.key,
    required this.reward,
    required this.currentBalance,
    required this.onConfirm,
  });

  @override
  State<RedeemConfirmationSheet> createState() =>
      _RedeemConfirmationSheetState();
}

class _RedeemConfirmationSheetState extends State<RedeemConfirmationSheet> {
  bool _isConfirming = false;

  Future<void> _onConfirmTap() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    await widget.onConfirm();
    // Parent pops the sheet — no need to pop here
  }

  @override
  Widget build(BuildContext context) {
    final balanceAfter = widget.currentBalance - widget.reward.pointsCost;
    final afterColor =
        balanceAfter >= 0 ? AppColors.success : AppColors.error;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ─────────────────────────────────────────────────────────
          Text('Confirm Redemption',
              style: AppTypography.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            widget.reward.rewardName,
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // ── Summary rows ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Cost',
                  value: '−${widget.reward.pointsCost} pts',
                  valueColor: AppColors.error,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Current Balance',
                  value: '${widget.currentBalance} pts',
                  valueColor: AppColors.textPrimary,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Balance After',
                  value: '$balanceAfter pts',
                  valueColor: afterColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 20),

          // ── Buttons ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Confirm
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : _onConfirmTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.background,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.check, size: 18),
                              const SizedBox(width: 8),
                              Text('Confirm',
                                  style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.background)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                // Cancel
                TextButton(
                  onPressed: _isConfirming
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Summary row helper ────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}
