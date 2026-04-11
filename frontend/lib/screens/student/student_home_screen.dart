// student_home_screen.dart — Live parking map with spot polling and geolocation gating
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_spacing.dart';
import '../../config/app_typography.dart';
import '../../config/constants.dart';
import '../../models/spot.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spots_provider.dart';
import '../../widgets/spot_tile.dart';

/// The main student parking map screen.
///
/// Hosted at tab index 0 inside [StudentShell]. Polls spot availability
/// every 30 seconds and gates reservations behind a geolocation check.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _shimmerController;
  late final Animation<double>   _shimmerOpacity;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _shimmerOpacity = Tween<double>(begin: 0.35, end: 0.8).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().startPolling();
      _checkGeolocation();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    context.read<SpotsProvider>().stopPolling();
    super.dispose();
  }

  // ── Geolocation ──────────────────────────────────────────────────────────────

  Future<void> _checkGeolocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) context.read<SpotsProvider>().setGeoResult(isTooFar: true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        AppConstants.campusLatitude, AppConstants.campusLongitude,
      );

      if (mounted) {
        context.read<SpotsProvider>().setGeoResult(
          isTooFar: (distanceMeters / 1000) > AppConstants.maxDistanceKm,
        );
      }
    } catch (_) {
      if (mounted) context.read<SpotsProvider>().setGeoResult(isTooFar: true);
    }
  }

  // ── Spot tap ─────────────────────────────────────────────────────────────────

  void _onSpotTapped(Spot spot) {
    context.read<SpotsProvider>().selectSpot(spot);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetRadius),
        ),
      ),
      builder: (_) => _SpotDetailSheet(
        spot: spot,
        isTooFar: context.read<SpotsProvider>().isTooFar,
      ),
    );
  }

  void _showCarpoolTooltip() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Carpool badge required for Zone B',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final spots = context.watch<SpotsProvider>();
    context.watch<AuthProvider>();

    final zoneASpots = spots.spotsForZone('A');
    final zoneBSpots = spots.spotsForZone('B');
    final zoneCSpots = spots.spotsForZone('C');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Map container — shrinks to content ────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
            ),
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.62,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF13161F),
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _buildMapBody(spots, zoneASpots, zoneBSpots, zoneCSpots),
                  ),
                ),
                // Polling indicator
                Positioned(
                  top: 10,
                  right: 10,
                  child: _PollingDot(refreshTick: spots.refreshTick),
                ),
              ],
            ),
          ),

          // ── Geo banner ────────────────────────────────────────────────────
          AnimatedOpacity(
            opacity: spots.isTooFar ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSlide(
              offset: spots.isTooFar ? Offset.zero : const Offset(0, -0.5),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: spots.isTooFar ? _buildGeoBanner() : const SizedBox.shrink(),
            ),
          ),

          const Spacer(),

          // ── Legend ────────────────────────────────────────────────────────
          _buildLegend(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  // ── Map body ─────────────────────────────────────────────────────────────────

  Widget _buildMapBody(
    SpotsProvider spots,
    List<Spot> zoneASpots,
    List<Spot> zoneBSpots,
    List<Spot> zoneCSpots,
  ) {
    if (spots.isLoading && spots.spots.isEmpty) return _buildShimmer();
    if (spots.error != null && spots.spots.isEmpty) return _buildError(spots);
    return _buildZoneLayout(zoneASpots, zoneBSpots, zoneCSpots);
  }

  // ── Zone layout ──────────────────────────────────────────────────────────────

  Widget _buildZoneLayout(
    List<Spot> zoneASpots,
    List<Spot> zoneBSpots,
    List<Spot> zoneCSpots,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Zone A label (long-press = geo bypass) ─────────────────────────
        GestureDetector(
          onLongPress: () {
            context.read<SpotsProvider>().bypassGeo();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dev mode: geolocation bypassed')),
            );
          },
          child: Text(
            'ZONE A',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
          ),
        ),
        const SizedBox(height: 8),

        // ── Zone A spots ───────────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: zoneASpots.map((s) => SpotTile(
            spot: s,
            onTap: s.isAvailable ? () => _onSpotTapped(s) : null,
          )).toList(),
        ),

        // ── Road divider ───────────────────────────────────────────────────
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

        // ── Zone B + Zone C side by side ───────────────────────────────────
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
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: zoneBSpots.map((s) => SpotTile(
                        spot: s,
                        onTap: _showCarpoolTooltip,
                        isMuted: true,
                      )).toList(),
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: AppColors.divider,
              ),

              // Zone C
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZONE C',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
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

  // ── Loading shimmer ───────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerOpacity,
      builder: (ctx, child) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < 3; i++) ...[
            Opacity(
              opacity: _shimmerOpacity.value,
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────────

  Widget _buildError(SpotsProvider spots) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.wifiOff, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(spots.error!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<SpotsProvider>().fetchSpots(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── Geo banner ────────────────────────────────────────────────────────────────

  Widget _buildGeoBanner() {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, 0),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        border: Border.all(color: AppColors.warning.withAlpha(76)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Icon(LucideIcons.mapPin, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Text(
            "You're too far to reserve. View only.",
            style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    const items = [
      (AppColors.available,   'Available'),
      (AppColors.reserved,    'Reserved'),
      (AppColors.occupied,    'Occupied'),
      (AppColors.unavailable, 'Unavailable'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: item.$1, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(item.$2, style: AppTypography.bodySmall),
          ],
        ),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed horizontal divider
// ─────────────────────────────────────────────────────────────────────────────

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
      ..color      = color
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

// ─────────────────────────────────────────────────────────────────────────────
// Polling indicator dot
// ─────────────────────────────────────────────────────────────────────────────

class _PollingDot extends StatefulWidget {
  final int refreshTick;
  const _PollingDot({required this.refreshTick});

  @override
  State<_PollingDot> createState() => _PollingDotState();
}

class _PollingDotState extends State<_PollingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_PollingDot old) {
    super.didUpdateWidget(old);
    if (old.refreshTick != widget.refreshTick) {
      _ctrl.forward(from: 0).then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spot detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SpotDetailSheet extends StatelessWidget {
  final Spot spot;
  final bool isTooFar;

  const _SpotDetailSheet({required this.spot, required this.isTooFar});

  String _accessDesc(String zoneCode) {
    switch (zoneCode) {
      case 'B': return 'Carpool badges only';
      case 'C': return 'Security managed';
      default:  return 'All badges welcome';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color      = spot.statusColor;
    final canReserve = spot.isAvailable && !isTooFar;
    final statusLabel = spot.status[0] + spot.status.substring(1).toLowerCase();

    String? disabledReason;
    if (isTooFar) {
      disabledReason = 'Move closer to campus to reserve';
    } else if (!spot.isAvailable) {
      disabledReason = 'This spot is currently ${spot.status.toLowerCase()}';
    }

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('Spot ${spot.spotLabel}', style: AppTypography.displayMedium),
          const SizedBox(height: 4),
          Text(spot.zoneName, style: AppTypography.bodyMedium),
          const SizedBox(height: 16),

          // Status pill
          Row(
            children: [
              Container(
                height: AppSpacing.badgeHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: AppTypography.labelSmall.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Access info
          Row(
            children: [
              const Icon(LucideIcons.info, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Text(_accessDesc(spot.zoneCode), style: AppTypography.bodyMedium),
            ],
          ),
          const SizedBox(height: 24),

          // Reserve button
          Opacity(
            opacity: canReserve ? 1.0 : 0.35,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: canReserve
                    ? () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reservations coming in Phase 2')),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: Text(
                  isTooFar
                      ? 'TOO FAR TO RESERVE'
                      : spot.isAvailable
                          ? 'RESERVE THIS SPOT'
                          : 'SPOT NOT AVAILABLE',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.background,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          if (disabledReason != null) ...[
            const SizedBox(height: 8),
            Text(disabledReason, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
