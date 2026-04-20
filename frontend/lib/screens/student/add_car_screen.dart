// add_car_screen.dart — S19: Add Car to Slot screen for carpool badge members
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/badge_member.dart';
import '../../providers/badge_provider.dart';

/// S19 — Add Car to Slot screen.
///
/// Lets a badge creator add an extra car to any accepted member's slot.
/// Expects [BadgeProvider.selectedBadge] to be populated from S16.
/// Filters members to ACCEPTED only — only filled slots can hold extra cars.
class AddCarScreen extends StatefulWidget {
  final int badgeId;
  const AddCarScreen({super.key, required this.badgeId});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  BadgeMember? _selectedMember;

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
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

  Future<void> _handleAddCar() async {
    final plateNumber = _plateController.text.trim().toUpperCase();
    final carModel    = _modelController.text.trim();

    if (_selectedMember == null ||
        _selectedMember!.userId == null ||
        plateNumber.isEmpty) {
      return;
    }

    final provider = context.read<BadgeProvider>();
    provider.clearOperationError();

    final success = await provider.addCar(
      badgeId:     widget.badgeId,
      plateNumber: plateNumber,
      forUserId:   _selectedMember!.userId!,
      carModel:    carModel.isNotEmpty ? carModel : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Car added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BadgeProvider>();
    final badge    = provider.selectedBadge;

    final tierColor = badge != null
        ? _badgeTierColor(badge.badgeType)
        : AppColors.individual;

    final acceptedMembers = badge?.members
            .where((m) => m.isAccepted && m.userId != null)
            .toList() ??
        [];

    final canSubmit = _selectedMember != null &&
        _plateController.text.trim().isNotEmpty &&
        !provider.isAddingCar;

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
        title: Text('Add Car to Slot', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: badge == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1 · Select member ─────────────────────────────────
                  Text(
                    'Add car for which member?',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  if (acceptedMembers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        'No accepted members yet. Members must accept their invitation first.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...acceptedMembers.map(
                      (m) => _buildMemberOption(m, tierColor),
                    ),

                  const SizedBox(height: 8),
                  Text(
                    'Each member can have multiple cars registered to their slot.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 24),

                  // ── 2 · Car details form ──────────────────────────────
                  Text(
                    'Car Details',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  // Plate number
                  TextField(
                    controller: _plateController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                    decoration: _inputDecoration(
                      label: 'Plate Number',
                      hint: 'e.g. ABC 1234',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Car model
                  TextField(
                    controller: _modelController,
                    keyboardType: TextInputType.text,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                    decoration: _inputDecoration(
                      label: 'Car Model (optional)',
                      hint: 'e.g. Toyota Corolla 2020',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optional — helps the guard identify the car',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 24),

                  // ── 3 · Add car button ────────────────────────────────
                  SizedBox(
                    height: AppSpacing.buttonHeight,
                    child: ElevatedButton(
                      onPressed: canSubmit ? _handleAddCar : null,
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
                      child: provider.isAddingCar
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
                                const Icon(LucideIcons.plus, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Car',
                                  style: AppTypography.labelLarge
                                      .copyWith(color: AppColors.background),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ── Error ─────────────────────────────────────────────
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

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── Member option card ────────────────────────────────────────────────────

  Widget _buildMemberOption(BadgeMember member, Color tierColor) {
    final isSelected = _selectedMember?.userId == member.userId;
    final name       = member.name ?? 'Member';
    final initial    = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => setState(() => _selectedMember = member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(26)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tierColor.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTypography.labelLarge.copyWith(color: tierColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + creator tag
            Expanded(
              child: Row(
                children: [
                  Text(
                    name,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  if (member.canInvite) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Creator',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Selection indicator
            if (isSelected)
              const Icon(LucideIcons.checkCircle2,
                  size: 22, color: AppColors.primary)
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.textTertiary, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Input decoration ──────────────────────────────────────────────────────

  InputDecoration _inputDecoration(
      {required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      hintText: hint,
      hintStyle:
          AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
