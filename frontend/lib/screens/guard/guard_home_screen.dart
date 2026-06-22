// guard_home_screen.dart — S21: Guard home dashboard
// Dark themed: alert banner (SPOT_CONTRADICTION), live counts, 2×2 action grid.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/guard_provider.dart';
import '../../services/notification_service.dart';

class GuardHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChange;
  const GuardHomeScreen({super.key, this.onTabChange});

  @override
  State<GuardHomeScreen> createState() => _GuardHomeScreenState();
}

class _GuardHomeScreenState extends State<GuardHomeScreen> {
  Timer?  _timeTimer;
  Timer?  _dataTimer;
  Timer?  _alertTimer;
  String  _currentTime = '';
  bool    _showAlert   = false;
  int?    _lastShownAlertId; // prevents re-showing the same notification

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const _kPageBg       = Color(0xFF0B1120);
  static const _kCardScanBg   = Color(0xFF0F1D2E);
  static const _kCardActiveBg = Color(0xFF162438);
  static const _kCardGuestBg  = Colors.white;
  static const _kCardReportBg = Color(0xFF2A0000);
  static const _kOverrideBg   = Color(0xFF0F1828);
  static const _kAlertBg      = Color(0xFF200000);
  static const _kGreen        = Color(0xFF4CAF50);
  static const _kAmber        = Color(0xFFEDB82A);

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) { if (mounted) _updateTime(); },
    );
    // Initial data load + start 30-second polling cycle
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _dataTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) { if (mounted) _loadData(); },
    );
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _dataTimer?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now  = DateTime.now();
    final h    = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final min  = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    setState(() => _currentTime = '${h.toString().padLeft(2, '0')}:$min $ampm');
  }

  Future<void> _loadData() async {
    // Refresh live entry counts
    await context.read<GuardProvider>().loadEntries();
    // Check for new SPOT_CONTRADICTION notifications
    await _checkContradictions();
  }

  Future<void> _checkContradictions() async {
    try {
      final page = await NotificationService().getNotifications(page: 0);
      final alert = page.content.where(
        (n) => !n.read && n.notificationType == 'SPOT_CONTRADICTION',
      ).firstOrNull;

      if (alert != null && alert.id != _lastShownAlertId && mounted) {
        _lastShownAlertId = alert.id;
        setState(() => _showAlert = true);
        // Auto-dismiss after 10 seconds
        _alertTimer?.cancel();
        _alertTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) setState(() => _showAlert = false);
        });
      }
    } catch (_) {
      // Silently fail — network issue should not break the dashboard
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final guard        = context.watch<GuardProvider>();
    final insideCount  = guard.entries.where((e) => e.status == 'ENTERED').length;
    final arrivingCount = guard.reservations.where((e) => e.status == 'ACTIVE').length;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Alert banner (SPOT_CONTRADICTION, auto-dismisses in 10s) ──
            if (_showAlert) _buildAlertBanner(),

            // ── Status row ─────────────────────────────────────────────────
            _buildStatusRow(insideCount, arrivingCount),

            const SizedBox(height: 20),

            // ── 2×2 Action grid ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildScanCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildActiveCard()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildGuestCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildReportCard()),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Spot Override button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildOverrideButton(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Alert banner ─────────────────────────────────────────────────────────

  Widget _buildAlertBanner() {
    return Container(
      color: _kAlertBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5252),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.alertTriangle,
              size: 16, color: Color(0xFFFF9800)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unauthorized vehicle detected',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF9800),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showAlert = false),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF4A0000),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status row ───────────────────────────────────────────────────────────

  Widget _buildStatusRow(int inside, int arriving) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          _StatusDot(color: _kGreen, label: '$inside inside'),
          const SizedBox(width: 16),
          _StatusDot(color: _kAmber, label: '$arriving arriving'),
          const Spacer(),
          Icon(LucideIcons.clock,
              size: 13, color: Colors.white.withAlpha(100)),
          const SizedBox(width: 5),
          Text(
            _currentTime,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: Colors.white.withAlpha(120),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action cards ─────────────────────────────────────────────────────────

  Widget _buildScanCard() {
    return _ActionCard(
      bg: _kCardScanBg,
      iconBg: const Color(0xFF1A3300),
      icon: LucideIcons.scan,
      iconColor: _kGreen,
      title: 'Scan QR',
      subtitle: 'Entry & exit gate',
      subtitleColor: _kGreen,
      titleColor: Colors.white,
      onTap: () => context.push('/guard/scanner'),
    );
  }

  Widget _buildActiveCard() {
    return _ActionCard(
      bg: _kCardActiveBg,
      iconBg: const Color(0xFF1E3050),
      icon: LucideIcons.clipboardList,
      iconColor: Colors.white.withAlpha(200),
      title: 'Active List',
      subtitle: 'Live reservations',
      subtitleColor: Colors.white.withAlpha(120),
      titleColor: Colors.white,
      onTap: () { if (widget.onTabChange != null) { widget.onTabChange!(1); } else { context.push('/guard/active'); } },
    );
  }

  Widget _buildGuestCard() {
    return _ActionCard(
      bg: _kCardGuestBg,
      iconBg: const Color(0xFFE8EEF8),
      icon: LucideIcons.car,
      iconColor: const Color(0xFF3D5A8A),
      title: 'Guest Parking',
      subtitle: 'Zone C management',
      subtitleColor: const Color(0xFF6B7280),
      titleColor: const Color(0xFF1A2035),
      onTap: () { if (widget.onTabChange != null) { widget.onTabChange!(2); } else { context.push('/guard/guest-parking'); } },
    );
  }

  Widget _buildReportCard() {
    return _ActionCard(
      bg: _kCardReportBg,
      iconBg: const Color(0xFF4A0000),
      icon: LucideIcons.alertTriangle,
      iconColor: const Color(0xFFFF5252),
      title: 'Report',
      subtitle: 'Log a violation',
      subtitleColor: const Color(0xFFFF6E6E),
      titleColor: Colors.white,
      onTap: () { if (widget.onTabChange != null) { widget.onTabChange!(3); } else { context.push('/guard/violation'); } },
    );
  }

  // ── Spot Override button ──────────────────────────────────────────────────

  Widget _buildOverrideButton() {
    return GestureDetector(
      onTap: () => context.push('/guard/override'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: _kOverrideBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Spot Override',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(120),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                size: 16, color: Colors.white.withAlpha(120)),
          ],
        ),
      ),
    );
  }
}

// ── Status dot ────────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  final Color  color;
  final String label;
  const _StatusDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatefulWidget {
  final Color      bg;
  final Color      iconBg;
  final IconData   icon;
  final Color      iconColor;
  final String     title;
  final String     subtitle;
  final Color      titleColor;
  final Color      subtitleColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.bg,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in rounded square container
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 26),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: widget.subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
