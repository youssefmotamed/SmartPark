// exit_success_screen.dart — Shown after the guard scans a student's exit QR.
// Celebrates points earned and shows a session summary (spot, duration).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/reservation_response.dart';
import '../../providers/reservation_provider.dart';

class ExitSuccessScreen extends StatefulWidget {
  const ExitSuccessScreen({super.key});

  @override
  State<ExitSuccessScreen> createState() => _ExitSuccessScreenState();
}

class _ExitSuccessScreenState extends State<ExitSuccessScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _animController;
  late final Animation<double>   _scaleAnim;
  late final Animation<double>   _fadeAnim;

  static const _kGreen   = Color(0xFF4CAF50);
  static const _kPageBg  = Color(0xFFEEF1F7);
  static const _kCardBg  = Colors.white;
  static const _kNavy    = Color(0xFF0F1828);
  static const _kText    = Color(0xFF1A2035);
  static const _kSub     = Color(0xFF6B7280);
  static const _kDivider = Color(0xFFF0F0F0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _zoneName(String code) {
    switch (code) {
      case 'A': return 'Main Parking';
      case 'B': return 'Carpool Zone';
      case 'C': return 'Guest Area';
      default:  return code;
    }
  }

  String _formatDuration(ReservationResponse? res) {
    if (res == null) return '—';
    final start = res.entryScannedAt ?? res.reservedAt;
    final end   = res.exitScannedAt  ?? DateTime.now();
    final diff  = end.difference(start);
    final hours = diff.inHours;
    final mins  = diff.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h  ${mins}m';
    return '${mins}m';
  }

  void _goHome() {
    context.read<ReservationProvider>().clearJustCompleted();
    context.go('/student/home');
  }

  void _goHistory() {
    context.read<ReservationProvider>().clearJustCompleted();
    context.push('/student/points/history');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final res    = context.read<ReservationProvider>().lastCompletedReservation;
    final points = res?.pointsEarned ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Dark hero area ─────────────────────────────────────────────────
          Expanded(
            flex: 45,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glow ring + circle + star
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _kGreen.withAlpha(70),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Inner solid circle with star
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF0B1120),
                            size: 56,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // +14 pts
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '+$points',
                            style: GoogleFonts.manrope(
                              fontSize: 72,
                              fontWeight: FontWeight.w800,
                              color: _kGreen,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: ' pts',
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: _kGreen.withAlpha(200),
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Points earned for this session',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: Colors.white.withAlpha(150),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Light card area ────────────────────────────────────────────────
          Expanded(
            flex: 55,
            child: Container(
              decoration: const BoxDecoration(
                color: _kPageBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Session Summary card ────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _kNavy,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Text(
                              'SESSION SUMMARY',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withAlpha(180),
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          // Spot row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Row(
                              children: [
                                Icon(LucideIcons.mapPin,
                                    size: 18, color: _kSub),
                                const SizedBox(width: 10),
                                Text('Spot',
                                    style: GoogleFonts.manrope(
                                        fontSize: 14, color: _kSub)),
                                const Spacer(),
                                Text(
                                  res != null
                                      ? '${res.spotLabel} · ${_zoneName(res.zoneCode)}'
                                      : '—',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _kText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                              height: 1,
                              thickness: 1,
                              color: _kDivider,
                              indent: 44),
                          // Duration row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                            child: Row(
                              children: [
                                Icon(LucideIcons.clock,
                                    size: 18, color: _kSub),
                                const SizedBox(width: 10),
                                Text('Duration',
                                    style: GoogleFonts.manrope(
                                        fontSize: 14, color: _kSub)),
                                const Spacer(),
                                Text(
                                  _formatDuration(res),
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _kText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Points earned card ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Green icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _kGreen.withAlpha(35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.star_rounded,
                                color: _kGreen, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Points earned',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kText,
                                  ),
                                ),
                                Text(
                                  'This parking session',
                                  style: GoogleFonts.manrope(
                                      fontSize: 12, color: _kSub),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+$points',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _kGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Back to Map button ─────────────────────────────────
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _goHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Back to Map',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── View Points History link ────────────────────────────
                    GestureDetector(
                      onTap: _goHistory,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'View Points History',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
