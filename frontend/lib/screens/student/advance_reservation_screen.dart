// advance_reservation_screen.dart — S14: Advance reservation with geolocation bypassed
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_spacing.dart';
import '../../config/app_typography.dart';
import '../../models/spot.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/spot_detail_sheet.dart';
import '../../widgets/spot_tile.dart';

/// S14 — Advance Reservation screen.
///
/// Identical to the home map but with geolocation fully bypassed.
/// Spots are tappable without distance gating; reserves via POST /reservations/advance.
class AdvanceReservationScreen extends StatefulWidget {
  const AdvanceReservationScreen({super.key});

  @override
  State<AdvanceReservationScreen> createState() =>
      _AdvanceReservationScreenState();
}

class _AdvanceReservationScreenState extends State<AdvanceReservationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().fetchSpots();
    });
  }

  // ── Spot tap ──────────────────────────────────────────────────────────────

  void _onSpotTapped(Spot spot) {
    if (spot.status != 'AVAILABLE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Spot ${spot.spotLabel} is currently ${spot.status.toLowerCase()}',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SpotDetailSheet(
        spot: spot,
        isTooFar: false,
        isAdvanceReservation: true,
      ),
    );
  }

  void _showCarpoolTooltip() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Carpool badge required for Zone B',
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final spots = context.watch<SpotsProvider>();

    final zoneASpots = spots.spotsForZone('A');
    final zoneBSpots = spots.spotsForZone('B');
    final zoneCSpots = spots.spotsForZone('C');

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
        title: Text('Advance Reservation',
            style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Geo-bypass banner ─────────────────────────────────────────────
          Container(
            color: AppColors.primaryGlow,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.mapPin,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Geolocation bypassed — reserve from anywhere',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),

          // ── Map container ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF13161F),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _buildMapBody(
                      spots, zoneASpots, zoneBSpots, zoneCSpots),
                ),
              ),
            ),
          ),

          // ── Legend ────────────────────────────────────────────────────────
          _buildLegend(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // ── Map body ──────────────────────────────────────────────────────────────

  Widget _buildMapBody(
    SpotsProvider spots,
    List<Spot> zoneASpots,
    List<Spot> zoneBSpots,
    List<Spot> zoneCSpots,
  ) {
    if (spots.isLoading && spots.spots.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (spots.error != null && spots.spots.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.wifiOff,
                  size: 40, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(spots.error!,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    context.read<SpotsProvider>().fetchSpots(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return _buildZoneLayout(zoneASpots, zoneBSpots, zoneCSpots);
  }

  Widget _buildZoneLayout(
    List<Spot> zoneASpots,
    List<Spot> zoneBSpots,
    List<Spot> zoneCSpots,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ZONE A',
          style: AppTypography.labelSmall
              .copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: zoneASpots
              .map((s) => SpotTile(
                    spot: s,
                    onTap: s.isAvailable ? () => _onSpotTapped(s) : null,
                  ))
              .toList(),
        ),

        // Road divider
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Expanded(child: _DashedDivider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'ROAD',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
              ),
              const Expanded(child: _DashedDivider()),
            ],
          ),
        ),

        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone B
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONE B',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: zoneBSpots
                          .map((s) => SpotTile(
                                spot: s,
                                onTap: _showCarpoolTooltip,
                                isMuted: true,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                color: AppColors.divider,
              ),

              // Zone C
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZONE C',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 8),
                  ...zoneCSpots.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SpotTile(spot: s, isGuardOnly: true),
                      )),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    const items = [
      (AppColors.available, 'Available'),
      (AppColors.reserved, 'Reserved'),
      (AppColors.occupied, 'Occupied'),
      (AppColors.unavailable, 'Unavailable'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: item.$1, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(item.$2, style: AppTypography.bodySmall),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ── Dashed divider (matches home screen road divider) ─────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedLinePainter(color: AppColors.divider),
      child: const SizedBox(height: 1),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}
