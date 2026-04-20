// create_badge_screen.dart — S17: Create Badge screen for SmartPark students
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../providers/badge_provider.dart';

/// S17 — Create Badge screen.
///
/// Lets a student pick a badge type (Individual or Carpool 2-5),
/// choose the semester/year, and submit to POST /badges.
/// On success pops this screen and pushes the new badge's S16 detail view.
class CreateBadgeScreen extends StatefulWidget {
  const CreateBadgeScreen({super.key});

  @override
  State<CreateBadgeScreen> createState() => _CreateBadgeScreenState();
}

class _CreateBadgeScreenState extends State<CreateBadgeScreen> {
  String? _selectedType;
  late int _selectedSemesterNumber;
  late int _selectedSemesterYear;

  static const _types = [
    'INDIVIDUAL',
    'CARPOOL_2',
    'CARPOOL_3',
    'CARPOOL_4',
    'CARPOOL_5',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedSemesterNumber = (now.month >= 4 && now.month <= 8) ? 2 : 1;
    _selectedSemesterYear   = now.year;
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

  String _typeLabel(String badgeType) {
    switch (badgeType) {
      case 'INDIVIDUAL': return 'Individual';
      case 'CARPOOL_2':  return 'Carpool (2 members)';
      case 'CARPOOL_3':  return 'Carpool (3 members)';
      case 'CARPOOL_4':  return 'Carpool (4 members)';
      case 'CARPOOL_5':  return 'Carpool (5 members)';
      default:           return badgeType;
    }
  }

  String _typeSubtitle(String badgeType) {
    switch (badgeType) {
      case 'INDIVIDUAL': return '1 spot, 1 car, for you only';
      case 'CARPOOL_2':  return '1 spot shared by 2 students';
      case 'CARPOOL_3':  return '1 spot shared by 3 students';
      case 'CARPOOL_4':  return '1 spot shared by 4 students';
      case 'CARPOOL_5':  return '1 spot shared by 5 students';
      default:           return '';
    }
  }

  String _typeInitial(String badgeType) =>
      badgeType == 'INDIVIDUAL' ? 'I' : badgeType.split('_').last;

  // ── Action ────────────────────────────────────────────────────────────────

  Future<void> _handleCreate() async {
    final provider = context.read<BadgeProvider>();
    provider.clearOperationError();

    final result = await provider.createBadge(
      badgeType:      _selectedType!,
      semesterNumber: _selectedSemesterNumber,
      semesterYear:   _selectedSemesterYear,
    );

    if (!mounted) return;

    if (result != null) {
      context.pop();
      context.push('/student/badges/${result.badgeId}');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<BadgeProvider>();
    final baseYear  = DateTime.now().year;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('Create Badge', style: AppTypography.displaySmall),
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
            // ── 1 · Badge type ────────────────────────────────────────────
            Text(
              'Select Badge Type',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...List.generate(_types.length, (i) => _buildTypeCard(_types[i])),
            const SizedBox(height: 24),

            // ── 2 · Semester ──────────────────────────────────────────────
            Text(
              'Semester',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSemesterNumberDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildSemesterYearDropdown(baseYear)),
              ],
            ),
            const SizedBox(height: 20),

            // ── 3 · Pricing info ──────────────────────────────────────────
            _buildInfoCard(),
            const SizedBox(height: 24),

            // ── 4 · Create button ─────────────────────────────────────────
            SizedBox(
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: (_selectedType != null && !provider.isCreating)
                    ? _handleCreate
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.surfaceHighlight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: provider.isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Badge',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.background),
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
                  style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Type card ─────────────────────────────────────────────────────────────

  Widget _buildTypeCard(String type) {
    final isSelected = _selectedType == type;
    final tierColor  = _badgeTierColor(type);

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? tierColor.withAlpha(26)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? tierColor : AppColors.divider,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tierColor.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _typeInitial(type),
                  style: AppTypography.labelLarge.copyWith(color: tierColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Label + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabel(type),
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _typeSubtitle(type),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Selection indicator
            if (isSelected)
              Icon(LucideIcons.checkCircle2, size: 22, color: tierColor)
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.textTertiary, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Semester dropdowns ────────────────────────────────────────────────────

  Widget _buildSemesterNumberDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedSemesterNumber,
      dropdownColor: AppColors.surfaceLight,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: _dropdownDecoration('Semester'),
      items: [1, 2]
          .map((n) => DropdownMenuItem(value: n, child: Text('Semester $n')))
          .toList(),
      onChanged: (v) => setState(() => _selectedSemesterNumber = v!),
    );
  }

  Widget _buildSemesterYearDropdown(int baseYear) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedSemesterYear,
      dropdownColor: AppColors.surfaceLight,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: _dropdownDecoration('Year'),
      items: [baseYear, baseYear + 1]
          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
          .toList(),
      onChanged: (v) => setState(() => _selectedSemesterYear = v!),
    );
  }

  InputDecoration _dropdownDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );

  // ── Info card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Badge pricing is handled at the university office. '
              'This creates your digital badge.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
