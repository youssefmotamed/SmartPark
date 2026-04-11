// guard_shell.dart — Guard role persistent shell: top bar + 4-tab bottom nav
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import 'guard_home_placeholder.dart';

/// Persistent layout wrapper for all guard screens.
///
/// Provides a custom top bar (wordmark + "Guard Dashboard" subtitle + bell)
/// and a 4-tab bottom navigation bar with amber [AppColors.warning] accent.
/// Uses [IndexedStack] so each tab's scroll position is preserved.
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
    _NavItem(icon: LucideIcons.clock,          label: 'Active'),
    _NavItem(icon: LucideIcons.userPlus,       label: 'Guest'),
    _NavItem(icon: LucideIcons.alertTriangle,  label: 'Violations'),
  ];

  static const _screens = [
    GuardHomePlaceholder(),
    _TabPlaceholder(title: 'Active Reservations', icon: LucideIcons.clock,         note: 'Coming in Phase 2'),
    _TabPlaceholder(title: 'Guest Parking',       icon: LucideIcons.userPlus,      note: 'Coming in Phase 2'),
    _TabPlaceholder(title: 'Violations',          icon: LucideIcons.alertTriangle, note: 'Coming in Phase 2'),
  ];

  late final List<AnimationController> _tabControllers;
  late final List<Animation<double>> _tabAnimations;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
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
            subtitle: 'Guard Dashboard',
            onBellTap: () => debugPrint('[GuardShell] notifications tapped'),
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
  final String subtitle;
  final VoidCallback onBellTap;

  const _TopBar({
    required this.accent,
    required this.subtitle,
    required this.onBellTap,
  });

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
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Wordmark + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Smart',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Park',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: accent.withAlpha(180)),
                ),
              ],
            ),
          ),
          // Bell
          GestureDetector(
            onTap: onBellTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.bell, size: 20, color: AppColors.textSecondary),
            ),
          ),
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
                style: AppTypography.labelSmall.copyWith(
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

/// Generic placeholder for tabs not yet implemented.
class _TabPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final String note;

  const _TabPlaceholder({
    required this.title,
    required this.icon,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTypography.displaySmall),
            const SizedBox(height: 8),
            Text(note, style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
