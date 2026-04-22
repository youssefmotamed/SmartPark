// badge_members_screen.dart — Shows all members of a specific admin badge.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../models/admin_badge.dart';

/// Displays all members belonging to [badge].
///
/// Receives the badge via the GoRouter `extra` parameter — no API call needed
/// since [AdminBadge] already carries the full members list from S31.
class BadgeMembersScreen extends StatelessWidget {
  final AdminBadge badge;

  const BadgeMembersScreen({super.key, required this.badge});

  static String _formatBadgeType(String badgeType) {
    switch (badgeType) {
      case 'INDIVIDUAL': return 'Individual';
      case 'CARPOOL_2':  return 'Carpool 2';
      case 'CARPOOL_3':  return 'Carpool 3';
      case 'CARPOOL_4':  return 'Carpool 4';
      case 'CARPOOL_5':  return 'Carpool 5';
      default:           return badgeType;
    }
  }

  static (Color, String) _statusInfo(String status) => switch (status) {
    'ACCEPTED' => (AppColors.success, 'Active'),
    _          => (AppColors.warning, 'Pending'),
  };

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
        title: Column(
          children: [
            Text('Badge Members', style: AppTypography.displaySmall),
            Text(
              '${_formatBadgeType(badge.badgeType)} — Badge #${badge.badgeId}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: badge.members.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildMembersList(),
              ],
            ),
    );
  }

  // ── Header stats card ──────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    final (statusColor, statusLabel) = _statusInfo(badge.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Members count
          _StatChip(
            value: '${badge.members.length}/${badge.maxSlots}',
            label: 'Members',
          ),

          Text('·',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textTertiary)),

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: AppTypography.labelSmall
                  .copyWith(color: statusColor, fontSize: 11),
            ),
          ),

          Text('·',
              style: AppTypography.bodyLarge
                  .copyWith(color: AppColors.textTertiary)),

          // Points
          Row(
            children: [
              const Icon(LucideIcons.star,
                  size: 13, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                '${badge.pointsBalance} pts',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Members list ───────────────────────────────────────────────────────────

  Widget _buildMembersList() {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        shrinkWrap:  true,
        physics:     const NeverScrollableScrollPhysics(),
        itemCount:   badge.members.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color:  AppColors.divider,
          indent: 72,
        ),
        itemBuilder: (_, i) => _MemberRow(member: badge.members[i]),
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users,
              size: 48, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text('No members found'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member row
// ─────────────────────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final AdminBadgeMember member;
  const _MemberRow({required this.member});

  static (Color, String) _statusInfo(String status) => switch (status) {
    'ACCEPTED' => (AppColors.success, 'Active'),
    _          => (AppColors.warning, 'Pending'),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusInfo(member.status);
    final initial = member.name.isNotEmpty
        ? member.name[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color:  color.withValues(alpha: 0.20),
              shape:  BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTypography.labelLarge.copyWith(color: color),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + student ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: AppTypography.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  member.studentId ?? '—',
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: 'JetBrains Mono',
                    color:      AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: AppTypography.labelSmall
                  .copyWith(color: color, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.labelLarge
                .copyWith(color: AppColors.textPrimary, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}
