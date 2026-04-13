// spot_tile.dart — Single parking spot tile widget for the SmartPark map
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/spot.dart';
import '../config/app_spacing.dart';
import 'error_dialog.dart';

/// A single parking spot on the map.
///
/// - Normal: solid border + filled background
/// - [isMuted] (Zone B, individual badge): dashed border, 45% opacity
/// - [isGuardOnly] (Zone C): dotted border, lock icon, non-tappable
///
/// Pulses briefly on status change via [didUpdateWidget].
class SpotTile extends StatefulWidget {
  final Spot spot;
  final VoidCallback? onTap;
  final bool isMuted;
  final bool isGuardOnly;

  const SpotTile({
    super.key,
    required this.spot,
    this.onTap,
    this.isMuted = false,
    this.isGuardOnly = false,
  });

  @override
  State<SpotTile> createState() => _SpotTileState();
}

class _SpotTileState extends State<SpotTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double>   _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0),  weight: 60),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(SpotTile old) {
    super.didUpdateWidget(old);
    if (old.spot.status != widget.spot.status) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    if (widget.isGuardOnly) {
      showErrorDialog(
        context,
        title: 'Security Only',
        message: 'Zone C spots are managed by security guards and cannot be reserved by students.',
      );
      return;
    }
    if (widget.isMuted) {
      showErrorDialog(
        context,
        title: 'Carpool Badge Required',
        message: 'Zone B is reserved for carpool badges only. Create or join a carpool badge to reserve spots here.',
      );
      return;
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.spot.statusColor;

    Widget tile;

    if (widget.isMuted) {
      // ── Dashed border, reduced fill, 45% opacity ──────────────────────────
      tile = Opacity(
        opacity: 0.45,
        child: Stack(
          children: [
            Container(
              width:  AppSpacing.spotWidth,
              height: AppSpacing.spotHeight,
              decoration: BoxDecoration(
                color:        color.withAlpha(25),
                borderRadius: BorderRadius.circular(AppSpacing.spotRadius),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.spot.spotLabel,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: color, letterSpacing: 0.5,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: color.withAlpha(128),
                  borderRadius: AppSpacing.spotRadius,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (widget.isGuardOnly) {
      // ── Dotted border, lock icon ──────────────────────────────────────────
      tile = Stack(
        children: [
          Container(
            width:  AppSpacing.spotWidth,
            height: AppSpacing.spotHeight,
            decoration: BoxDecoration(
              color:        color.withAlpha(30),
              borderRadius: BorderRadius.circular(AppSpacing.spotRadius),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.lock, size: 10, color: color),
                const SizedBox(height: 2),
                Text(
                  widget.spot.spotLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: color, letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: color.withAlpha(180),
                borderRadius: AppSpacing.spotRadius,
                dashLength: 2,
                gapLength: 2,
              ),
            ),
          ),
        ],
      );
    } else {
      // ── Normal solid border ────────────────────────────────────────────────
      tile = Container(
        width:  AppSpacing.spotWidth,
        height: AppSpacing.spotHeight,
        decoration: BoxDecoration(
          color:        color.withAlpha(30),
          borderRadius: BorderRadius.circular(AppSpacing.spotRadius),
          border:       Border.all(color: color.withAlpha(180), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.spot.spotLabel,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: color, letterSpacing: 0.5,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: ScaleTransition(scale: _scaleAnim, child: tile),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed / dotted border painter
// ─────────────────────────────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color  color;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  const _DashedBorderPainter({
    required this.color,
    this.dashLength   = 4,
    this.gapLength    = 3,
    this.borderRadius = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color      = color
      ..strokeWidth = 1.5
      ..style      = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
