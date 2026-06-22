// guest_parking_screen.dart — S25: Guard creates a guest parking entry for Zone C
// Light gray page, amber plate field, ALL Zone C spot cards, purpose input.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/spot.dart';
import '../../providers/guard_provider.dart';
import '../../providers/spots_provider.dart';

class GuestParkingScreen extends StatefulWidget {
  const GuestParkingScreen({super.key});

  @override
  State<GuestParkingScreen> createState() => _GuestParkingScreenState();
}

class _GuestParkingScreenState extends State<GuestParkingScreen> {
  final _plateController   = TextEditingController();
  final _purposeController = TextEditingController();
  Spot? _selectedSpot;

  static const _kPageBg    = Color(0xFFEEF1F7);
  static const _kCardText  = Color(0xFF1A2035);
  static const _kCardSub   = Color(0xFF6B7280);
  static const _kLabel     = Color(0xFF374151);
  static const _kAmberFill = Color(0xFFFFFDE7);
  static const _kAmberBorder = Color(0xFFFFD54F);
  static const _kGreen     = Color(0xFF2E7D32);
  static const _kRed       = Color(0xFFD32F2F);
  static const _kRedFill   = Color(0xFFFFEBEE);
  static const _kRedBorder  = Color(0xFFFFCDD2);
  static const _kButtonAmber = Color(0xFFEDB82A);

  @override
  void initState() {
    super.initState();
    _plateController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().fetchSpots();
    });
  }

  @override
  void dispose() {
    _plateController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty || _selectedSpot == null) return;

    final provider = context.read<GuardProvider>();
    provider.clearOperationError();

    final result = await provider.createGuestParking(
      spotId: _selectedSpot!.id,
      guestPlateNumber: plate,
      purpose: _purposeController.text.trim().isNotEmpty
          ? _purposeController.text.trim()
          : null,
    );

    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Guest parking created — Spot ${result.spotLabel}'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _plateController.clear();
      _purposeController.clear();
      setState(() => _selectedSpot = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guard  = context.watch<GuardProvider>();
    final spots  = context.watch<SpotsProvider>();
    final zoneC  = spots.spots
        .where((s) => s.zoneCode == 'C')
        .toList()
      ..sort((a, b) => a.spotLabel.compareTo(b.spotLabel));

    final canCreate = _plateController.text.trim().isNotEmpty
        && _selectedSpot != null
        && _selectedSpot!.isAvailable
        && !guard.isCreatingGuest;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Zone subtitle strip ───────────────────────────────────────────
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Icon(LucideIcons.shield,
                    size: 14, color: Colors.white.withAlpha(120)),
                const SizedBox(width: 8),
                Text(
                  'Zone C · Guest Area — Security Managed',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white.withAlpha(160),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Plate input ─────────────────────────────────────────
                  _SectionLabel('GUEST LICENSE PLATE'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: _kCardText, letterSpacing: 3,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ABC 1234',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 22, color: Colors.black26,
                        letterSpacing: 3,
                      ),
                      filled: true,
                      fillColor: _kAmberFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _kAmberBorder, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _kAmberBorder, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFFFB300), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Spot selector ────────────────────────────────────────
                  _SectionLabel('ASSIGN SPOT'),
                  const SizedBox(height: 10),

                  if (spots.isLoading && zoneC.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(
                            color: Color(0xFFEDB82A), strokeWidth: 2),
                      ),
                    )
                  else if (zoneC.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(LucideIcons.alertCircle,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('No Zone C spots found',
                            style: GoogleFonts.manrope(
                                color: AppColors.error, fontSize: 13)),
                      ]),
                    )
                  else
                    Row(
                      children: zoneC.map((spot) {
                        final isSelected = _selectedSpot?.id == spot.id;
                        final isOccupied = !spot.isAvailable;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: spot == zoneC.last ? 0 : 10),
                            child: GestureDetector(
                              onTap: isOccupied
                                  ? null
                                  : () =>
                                      setState(() => _selectedSpot = spot),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isOccupied
                                      ? _kRedFill
                                      : isSelected
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOccupied
                                        ? _kRedBorder
                                        : isSelected
                                            ? _kGreen
                                            : const Color(0xFFE5E7EB),
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      spot.spotLabel,
                                      style: GoogleFonts.manrope(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: isOccupied
                                            ? const Color(0xFFE57373)
                                            : _kCardText,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 6, height: 6,
                                          decoration: BoxDecoration(
                                            color: isOccupied
                                                ? _kRed
                                                : _kGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOccupied
                                              ? 'Occupied'
                                              : 'Available',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isOccupied
                                                ? _kRed
                                                : _kGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 20),

                  // ── Purpose input ────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'PURPOSE',
                        style: GoogleFonts.manrope(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: _kLabel, letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(OPTIONAL)',
                        style: GoogleFonts.manrope(
                          fontSize: 11, color: _kCardSub, letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _purposeController,
                    maxLines: 2,
                    style: GoogleFonts.manrope(
                        fontSize: 14, color: _kCardText),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Faculty visit, Delivery, Conference',
                      hintStyle: GoogleFonts.manrope(
                          fontSize: 14, color: Colors.black38),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFEDB82A), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Submit button ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canCreate ? _handleCreate : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kButtonAmber,
                        disabledBackgroundColor:
                            const Color(0xFFDDE2EE),
                        foregroundColor: _kCardText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: guard.isCreatingGuest
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Log Guest Vehicle',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: canCreate
                                    ? _kCardText
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                    ),
                  ),

                  if (guard.operationError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.alertCircle,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(guard.operationError!,
                                style: GoogleFonts.manrope(
                                    color: AppColors.error,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: const Color(0xFF374151), letterSpacing: 1.2,
      ),
    );
  }
}
