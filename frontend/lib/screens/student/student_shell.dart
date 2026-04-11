// student_shell.dart — Student role persistent shell: top bar + 4-tab bottom nav
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import 'student_home_screen.dart';
import 'profile_screen.dart';

/// Persistent layout wrapper for all student screens.
///
/// Provides a custom top bar (wordmark + bell + avatar) and a 4-tab
/// bottom navigation bar. Uses [IndexedStack] so each tab's scroll
/// position and state are preserved when switching.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  static const _accent = AppColors.primary;

  static const _navItems = [
    _NavItem(icon: LucideIcons.mapPin,  label: 'Map'),
    _NavItem(icon: LucideIcons.zap,     label: 'Points'),
    _NavItem(icon: LucideIcons.shield,  label: 'Badge'),
    _NavItem(icon: LucideIcons.user,    label: 'Profile'),
  ];

  static final _screens = [
    const StudentHomeScreen(),
    const _TabPlaceholder(title: 'Points',  icon: LucideIcons.zap,   note: 'Coming in Phase 3'),
    const _TabPlaceholder(title: 'Badge',   icon: LucideIcons.shield, note: 'Coming in Phase 3'),
    const ProfileScreen(),
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
            points: 85, // TODO: replace with live value from PointsProvider in Phase 3
            onBellTap: () => debugPrint('[StudentShell] notifications tapped'),
            onAvatarTap: () => _onTabTapped(3),
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
  final VoidCallback onAvatarTap;
  final int points;

  const _TopBar({
    required this.accent,
    required this.onBellTap,
    required this.onAvatarTap,
    required this.points,
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
          // Wordmark
          Expanded(
            child: Row(
              children: [
                Text(
                  'Smart',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Park',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                // Live dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.available,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.available.withAlpha(120), blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Points pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(28),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.warning.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.star, size: 13, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  '$points',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Bell
          _IconButton(icon: LucideIcons.bell, onTap: onBellTap),
          const SizedBox(width: AppSpacing.sm),
          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withAlpha(80), width: 1),
              ),
              child: Center(
                child: Text(
                  'W',
                  style: AppTypography.labelMedium.copyWith(color: accent),
                ),
              ),
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
              // Indicator dot
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
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
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
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
