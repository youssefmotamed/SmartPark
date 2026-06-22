// active_reservations_screen.dart — S24: Active entries tab (reservations + guest)
// Light gray background, pill tab selector, status-colored reservation cards.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/guard_entry.dart';
import '../../providers/guard_provider.dart';

class ActiveReservationsScreen extends StatefulWidget {
  const ActiveReservationsScreen({super.key});

  @override
  State<ActiveReservationsScreen> createState() =>
      _ActiveReservationsScreenState();
}

class _ActiveReservationsScreenState extends State<ActiveReservationsScreen> {
  int _tab = 0;

  static const _kPageBg    = Color(0xFFEEF1F7);
  static const _kCardText  = Color(0xFF1A2035);
  static const _kCardSub   = Color(0xFF6B7280);
  static const _kGreen     = Color(0xFF2E7D32);
  static const _kGreenBg   = Color(0xFFE8F5E9);
  static const _kAmber     = Color(0xFFE65100);
  static const _kAmberBg   = Color(0xFFFFF8E1);
  static const _kTabNavy   = Color(0xFF1A2A3A);
  static const _kTabGreen  = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuardProvider>().loadEntries();
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatLeaveTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _elapsed(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m ago';
    return '${diff.inMinutes}m ago';
  }

  String _zoneName(String spotLabel) {
    if (spotLabel.isEmpty) return '';
    switch (spotLabel[0]) {
      case 'A': return 'Main Parking';
      case 'B': return 'Carpool Zone';
      case 'C': return 'Guest Area';
      default:  return '';
    }
  }

  String _badgeName(String? type) {
    switch (type) {
      case 'CARPOOL_2': return 'Carpool 2';
      case 'CARPOOL_3': return 'Carpool 3';
      case 'CARPOOL_4': return 'Carpool 4';
      case 'CARPOOL_5': return 'Carpool 5';
      default:          return 'Individual';
    }
  }

  String _resId(int id) =>
      'RES-${id.toRadixString(16).toUpperCase().padLeft(4, '0')}';

  Future<void> _completeGuest(int guestParkingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Complete?',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700, color: _kCardText)),
        content: Text('Mark this guest as departed?',
            style: GoogleFonts.manrope(color: _kCardSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: GoogleFonts.manrope(color: _kCardSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kTabGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Complete',
                style: GoogleFonts.manrope(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok =
        await context.read<GuardProvider>().completeGuestParking(guestParkingId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Guest parking completed' : 'Failed'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider     = context.watch<GuardProvider>();
    final reservations = provider.reservations;
    final guests       = provider.guestEntries;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: Column(
        children: [
          // ── Pill tab selector ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: _kTabNavy,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _PillTab(
                    label: 'Reservations (${reservations.length})',
                    active: _tab == 0,
                    activeColor: _kTabGreen,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  _PillTab(
                    label: 'Guest Parking (${guests.length})',
                    active: _tab == 1,
                    activeColor: _kTabGreen,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: provider.isLoadingEntries && provider.entries.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50)))
                : provider.entriesError != null && provider.entries.isEmpty
                    ? _buildError(provider)
                    : _tab == 0
                        ? _buildReservations(reservations, provider)
                        : _buildGuests(guests, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildError(GuardProvider p) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(p.entriesError!,
              style: GoogleFonts.manrope(color: _kCardSub),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: p.loadEntries,
            child: Text('Retry',
                style: GoogleFonts.manrope(
                    color: _kTabGreen, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildReservations(List<GuardEntry> list, GuardProvider p) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.clipboardList,
                size: 48, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 12),
            Text('No active reservations',
                style: GoogleFonts.manrope(
                    fontSize: 15, color: _kCardSub)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: p.loadEntries,
      color: _kTabGreen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: list.length,
        itemBuilder: (_, i) => _ReservationCard(
          entry:    list[i],
          resId:    _resId(list[i].id),
          zoneName: _zoneName(list[i].spotLabel),
          badge:    _badgeName(list[i].badgeType),
          elapsed:  _elapsed(list[i].reservedAt),
          leaveBy:  _formatLeaveTime(list[i].expectedLeaveTime),
          kGreen: _kGreen, kGreenBg: _kGreenBg,
          kAmber: _kAmber, kAmberBg: _kAmberBg,
          kCardText: _kCardText, kCardSub: _kCardSub,
        ),
      ),
    );
  }

  Widget _buildGuests(List<GuardEntry> list, GuardProvider p) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.car, size: 48, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 12),
            Text('No guest parking active',
                style: GoogleFonts.manrope(fontSize: 15, color: _kCardSub)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: p.loadEntries,
      color: _kTabGreen,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: list.length,
        itemBuilder: (_, i) => _GuestCard(
          entry:      list[i],
          elapsed:    _elapsed(list[i].createdAt),
          onComplete: _completeGuest,
          kCardText: _kCardText, kCardSub: _kCardSub,
        ),
      ),
    );
  }
}

// ── Pill tab ──────────────────────────────────────────────────────────────────

class _PillTab extends StatelessWidget {
  final String label;
  final bool   active;
  final Color  activeColor;
  final VoidCallback onTap;
  const _PillTab({
    required this.label, required this.active,
    required this.activeColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF1A2035) : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reservation card ──────────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final GuardEntry entry;
  final String resId, zoneName, badge, elapsed, leaveBy;
  final Color kGreen, kGreenBg, kAmber, kAmberBg, kCardText, kCardSub;

  const _ReservationCard({
    required this.entry,
    required this.resId, required this.zoneName,
    required this.badge, required this.elapsed, required this.leaveBy,
    required this.kGreen, required this.kGreenBg,
    required this.kAmber, required this.kAmberBg,
    required this.kCardText, required this.kCardSub,
  });

  @override
  Widget build(BuildContext context) {
    final isInside = entry.status == 'ENTERED';
    final statusBg   = isInside ? kGreenBg : kAmberBg;
    final statusColor = isInside ? kGreen   : kAmber;
    final statusLabel = isInside ? 'INSIDE'  : 'EN ROUTE';
    final plates      = entry.plateNumbers ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration:
                      BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: statusColor, letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  resId,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: statusColor.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + plate
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.studentName ?? '—',
                        style: GoogleFonts.manrope(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: kCardText,
                        ),
                      ),
                    ),
                    if (plates.isNotEmpty)
                      Text(
                        plates.first.replaceAll('', ' ').trim(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: kCardText, letterSpacing: 2,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Location + badge
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 13, color: kCardSub),
                    const SizedBox(width: 5),
                    Text(
                      '${entry.spotLabel} · $zoneName',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: kCardSub),
                    ),
                    const SizedBox(width: 14),
                    Icon(LucideIcons.shield, size: 13, color: kCardSub),
                    const SizedBox(width: 5),
                    Text(
                      badge,
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: kCardSub),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Time row
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 13, color: kCardSub),
                    const SizedBox(width: 5),
                    Text(
                      '${isInside ? 'Entered' : 'Reserved'} $elapsed',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: kCardSub),
                    ),
                    const Spacer(),
                    Text(
                      'Leave by ',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: kCardSub),
                    ),
                    Text(
                      leaveBy,
                      style: GoogleFonts.manrope(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: kCardText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guest card ────────────────────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  final GuardEntry entry;
  final String elapsed;
  final void Function(int) onComplete;
  final Color kCardText, kCardSub;

  const _GuestCard({
    required this.entry, required this.elapsed,
    required this.onComplete, required this.kCardText, required this.kCardSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1565C0), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text('GUEST',
                    style: GoogleFonts.manrope(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1565C0), letterSpacing: 0.5,
                    )),
                const Spacer(),
                Text(
                  entry.spotLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: const Color(0xFF1565C0).withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.guestPlateNumber ?? '—',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: kCardText, letterSpacing: 2,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onComplete(entry.id),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                        ),
                      ),
                      child: Text('Complete',
                          style: GoogleFonts.manrope(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          )),
                    ),
                  ],
                ),
                if (entry.purpose != null && entry.purpose!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(entry.purpose!,
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: kCardSub)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.clock, size: 13, color: kCardSub),
                    const SizedBox(width: 5),
                    Text('Created $elapsed',
                        style:
                            GoogleFonts.manrope(fontSize: 13, color: kCardSub)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
