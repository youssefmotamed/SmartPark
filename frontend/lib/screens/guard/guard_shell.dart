// guard_shell.dart — Guard role persistent shell: top bar + 4-tab bottom nav
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_spacing.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_bell.dart';
import 'guard_home_screen.dart';
import 'active_reservations_screen.dart';
import 'guest_parking_screen.dart';
import 'violation_report_screen.dart';

class GuardShell extends StatefulWidget {
  const GuardShell({super.key});

  @override
  State<GuardShell> createState() => _GuardShellState();
}

class _GuardShellState extends State<GuardShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  static const _accent = AppColors.warning;

  static const _navItems = [
    _NavItem(icon: LucideIcons.qrCode,        label: 'Scan'),
    _NavItem(icon: LucideIcons.clipboardList,  label: 'Active'),
    _NavItem(icon: LucideIcons.car,            label: 'Guest'),
    _NavItem(icon: LucideIcons.alertTriangle,  label: 'Violations'),
  ];

  late final List<Widget> _screens;

  late final List<AnimationController> _tabControllers;
  late final List<Animation<double>> _tabAnimations;

  @override
  void initState() {
    super.initState();
    _screens = [
      GuardHomeScreen(onTabChange: _onTabTapped),
      const ActiveReservationsScreen(),
      const GuestParkingScreen(),
      const ViolationReportScreen(),
    ];
    _tabControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    _tabAnimations = _tabControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    context.read<NotificationProvider>().stopPolling();
    for (final c in _tabControllers) { c.dispose(); }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    _tabControllers[index].forward(from: 0);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopBar(
            accent: _accent,
            onBellTap: () => context.go('/guard/notifications'),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        animations: _tabAnimations,
        accent: _accent,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Color accent;
  final VoidCallback onBellTap;

  const _TopBar({
    required this.accent,
    required this.onBellTap,
  });

  static const _kBadgeAmber  = Color(0xFFEDB82A);
  static const _kGuardGreen  = Color(0xFF2D5016);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 12,
        bottom: 12,
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          // P badge
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _kBadgeAmber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'P',
                style: GoogleFonts.manrope(
                  fontSize: 20, fontWeight: FontWeight.w900,
                  color: Colors.white, height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // SmartPark wordmark
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Smart',
                  style: GoogleFonts.manrope(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary, height: 1,
                  ),
                ),
                TextSpan(
                  text: 'Park',
                  style: GoogleFonts.manrope(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: _kBadgeAmber, height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // GUARD role chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kGuardGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'GUARD',
              style: GoogleFonts.manrope(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: 0.8,
              ),
            ),
          ),
          const Spacer(),
          // Notification bell
          NotificationBell(onTap: onBellTap),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom nav
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final List<Animation<double>> animations;
  final Color accent;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.animations,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) => _buildItem(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: animations[index],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isActive ? 4 : 0,
                height: 4,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              Icon(
                items[index].icon,
                size: 22,
                color: isActive ? accent : AppColors.textTertiary,
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? accent : AppColors.textTertiary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(items[index].label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

