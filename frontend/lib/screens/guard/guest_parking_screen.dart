// guest_parking_screen.dart — S25: Guard creates a guest parking entry for
// a Zone C spot. Plate number, spot selector, and optional purpose field.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/spot.dart';
import '../../providers/guard_provider.dart';
import '../../providers/spots_provider.dart';

/// S25 — Guest Parking screen.
///
/// Guards use this to register a guest vehicle in a Zone C spot.
/// Loads current Zone C spot availability from [SpotsProvider].
class GuestParkingScreen extends StatefulWidget {
  const GuestParkingScreen({super.key});

  @override
  State<GuestParkingScreen> createState() => _GuestParkingScreenState();
}

class _GuestParkingScreenState extends State<GuestParkingScreen> {
  final TextEditingController _plateController   = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  Spot? _selectedSpot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().fetchSpots();
    });
    // Rebuild when plate text changes (to enable/disable Create button)
    _plateController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _plateController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  // ── Create action ─────────────────────────────────────────────────────────

  Future<void> _handleCreate() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty || _selectedSpot == null) return;

    final provider = context.read<GuardProvider>();
    provider.clearOperationError();

    final result = await provider.createGuestParking(
      spotId:          _selectedSpot!.id,
      guestPlateNumber: plate,
      purpose: _purposeController.text.trim().isNotEmpty
          ? _purposeController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guest parking created — Spot ${result.spotLabel}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/guard/home');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final guardProvider = context.watch<GuardProvider>();
    final spotsProvider = context.watch<SpotsProvider>();

    final zoneCSpots = spotsProvider.spots
        .where((s) => s.zoneCode == 'C' && s.isAvailable)
        .toList()
      ..sort((a, b) => a.spotLabel.compareTo(b.spotLabel));

    final bool canCreate = _plateController.text.trim().isNotEmpty
        && _selectedSpot != null
        && !guardProvider.isCreatingGuest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.textSecondary),
          onPressed: () => context.go('/guard/home'),
        ),
        title: Text('Guest Parking', style: AppTypography.displaySmall),
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
            const SizedBox(height: 8),

            // ── Plate number input ─────────────────────────────────────────
            Text('Guest Plate Number',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller:          _plateController,
              textCapitalization:  TextCapitalization.characters,
              keyboardType:        TextInputType.text,
              style: GoogleFonts.jetBrainsMono(
                fontSize:      14,
                fontWeight:    FontWeight.w500,
                color:         AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText:    'e.g. GUEST 1234',
                hintStyle:   AppTypography.bodyMedium,
                filled:      true,
                fillColor:   AppColors.surfaceLight,
                prefixIcon:  const Icon(
                  LucideIcons.car,
                  size:  20,
                  color: AppColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 24),

            // ── Zone C spot selector ───────────────────────────────────────
            Text('Select Zone C Spot',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),

            if (spotsProvider.isLoading && zoneCSpots.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(
                      color: AppColors.warning, strokeWidth: 2),
                ),
              )
            else if (zoneCSpots.isEmpty)
              _buildNoSpotsWarning()
            else
              _buildSpotRow(zoneCSpots),

            const SizedBox(height: 24),

            // ── Purpose input (optional) ───────────────────────────────────
            Text('Purpose (optional)',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _purposeController,
              maxLines:   2,
              style:      AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText:  'e.g. Parent registration, Delivery',
                hintStyle: AppTypography.bodyMedium,
                filled:    true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
                helperText:  'Optional — helps identify the reason for the visit',
                helperStyle: AppTypography.bodySmall,
              ),
            ),

            const SizedBox(height: 32),

            // ── Create button ──────────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: canCreate ? _handleCreate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:         AppColors.primary,
                  disabledBackgroundColor: AppColors.divider,
                  foregroundColor:         AppColors.background,
                  elevation:               0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: guardProvider.isCreatingGuest
                    ? const SizedBox(
                        width:  20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color:       Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Guest Parking',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.background),
                      ),
              ),
            ),

            // ── Operation error ────────────────────────────────────────────
            if (guardProvider.operationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        guardProvider.operationError!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error),
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

  // ── Spot row ──────────────────────────────────────────────────────────────

  Widget _buildSpotRow(List<Spot> spots) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: spots.map((spot) {
          final isSelected = _selectedSpot?.id == spot.id;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSpot = spot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width:  80,
                height: 70,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    spot.spotLabel,
                    style: AppTypography.displaySmall.copyWith(
                      fontSize: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── No spots warning ──────────────────────────────────────────────────────

  Widget _buildNoSpotsWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Text(
            'No Zone C spots available',
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
