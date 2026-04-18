// invite_member_screen.dart — S18: Invite Member screen for carpool badges
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/badge_detail.dart';
import '../../models/badge_member.dart';
import '../../providers/badge_provider.dart';

/// S18 — Invite Member screen.
///
/// Lets a badge creator invite another student to join their carpool badge
/// by entering the student's university ID. Expects [BadgeProvider.selectedBadge]
/// to already be populated from S16; gracefully handles a null badge.
class InviteMemberScreen extends StatefulWidget {
  final int badgeId;
  const InviteMemberScreen({super.key, required this.badgeId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _studentIdController = TextEditingController();
  bool _showSuccess = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _badgeTierColor(String badgeType) {
    switch (badgeType) {
      case 'CARPOOL_2': return AppColors.carpool2;
      case 'CARPOOL_3': return AppColors.carpool3;
      case 'CARPOOL_4': return AppColors.carpool4;
      case 'CARPOOL_5': return AppColors.carpool5;
      default:          return AppColors.individual;
    }
  }

  // ── Action ────────────────────────────────────────────────────────────────

  Future<void> _handleInvite() async {
    final studentId = _studentIdController.text.trim();
    if (studentId.isEmpty) return;

    final provider = context.read<BadgeProvider>();
    provider.clearOperationError();

    final success = await provider.inviteMember(widget.badgeId, studentId);

    if (!mounted) return;

    if (success) {
      _studentIdController.clear();
      setState(() => _showSuccess = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<BadgeProvider>();
    final badge     = provider.selectedBadge;
    final tierColor = badge != null
        ? _badgeTierColor(badge.badgeType)
        : AppColors.individual;

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
        title: Text('Invite Member', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1 · Members summary ───────────────────────────────────────
            if (badge != null) ...[
              _buildMembersSummary(badge, tierColor),
              const SizedBox(height: 24),
            ],

            // ── 2 · Student ID field ──────────────────────────────────────
            Text(
              'Student ID',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _studentIdController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 221000590',
                hintStyle: AppTypography.bodySmall
                    .copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Text(
              "Enter the student's university ID number",
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 20),

            // ── 3 · Send button ───────────────────────────────────────────
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: (_studentIdController.text.trim().isNotEmpty &&
                        !provider.isInviting)
                    ? _handleInvite
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.surfaceHighlight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: provider.isInviting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.userPlus, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Send Invitation',
                            style: AppTypography.labelLarge
                                .copyWith(color: AppColors.background),
                          ),
                        ],
                      ),
              ),
            ),

            // ── Error ─────────────────────────────────────────────────────
            if (provider.operationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(38),
                  border: Border.all(color: AppColors.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.operationError!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.error),
                ),
              ),
            ],

            // ── Success ───────────────────────────────────────────────────
            if (_showSuccess) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(38),
                  border: Border.all(color: AppColors.success),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Invitation sent! The student will receive a notification.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Members summary ───────────────────────────────────────────────────────

  Widget _buildMembersSummary(BadgeDetail badge, Color tierColor) {
    final members        = badge.members;
    final slotsRemaining = badge.maxSlots - members.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Members',
          style: AppTypography.labelMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: members.asMap().entries.map((entry) {
              final i      = entry.key;
              final m      = entry.value;
              final isLast = i == members.length - 1;
              return _buildMemberRow(m, tierColor, isLast: isLast);
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(LucideIcons.users,
                size: 13, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              '$slotsRemaining slot${slotsRemaining == 1 ? '' : 's'} remaining',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.warning),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberRow(BadgeMember m, Color tierColor,
      {required bool isLast}) {
    final name        = m.name ?? 'Invited Member';
    final initial     = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final statusColor = m.isAccepted ? AppColors.success : AppColors.warning;
    final statusLabel = m.isAccepted ? 'Active' : 'Pending';

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tierColor.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: AppTypography.labelSmall
                        .copyWith(color: tierColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1, color: AppColors.divider, indent: 56),
      ],
    );
  }
}
