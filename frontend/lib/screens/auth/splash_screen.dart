// splash_screen.dart — Animated launch screen: logo entrance, pulsing dots, auth redirect
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';

/// Full-screen animated splash shown at app launch.
///
/// Sequence:
/// 1. Logo fades + scales in (600ms)
/// 2. Three pulsing dots appear staggered from 400ms
/// 3. Auth check runs in parallel with animations
/// 4. After ≥1.5 s total, screen fades out (300ms) then navigates
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo entrance ──────────────────────────────────────────────────────────
  late final AnimationController _logoController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  // ── Screen exit ────────────────────────────────────────────────────────────
  late final AnimationController _exitController;
  late final Animation<double> _exitOpacity;

  // ── Pulsing dots ───────────────────────────────────────────────────────────
  late final AnimationController _dot1Controller;
  late final AnimationController _dot2Controller;
  late final AnimationController _dot3Controller;
  late final Animation<double> _dot1Opacity;
  late final Animation<double> _dot2Opacity;
  late final Animation<double> _dot3Opacity;

  @override
  void initState() {
    super.initState();

    // Logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoOpacity = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Exit (runs forward → opacity 1→0)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // Dots
    _dot1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _dot2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _dot3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _dot1Opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _dot1Controller, curve: Curves.easeInOut),
    );
    _dot2Opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _dot2Controller, curve: Curves.easeInOut),
    );
    _dot3Opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _dot3Controller, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _exitController.dispose();
    _dot1Controller.dispose();
    _dot2Controller.dispose();
    _dot3Controller.dispose();
    super.dispose();
  }

  Future<void> _startSequence() async {
    // ① Logo entrance — immediate
    _logoController.forward();

    // ② Dots — staggered from 400ms after launch
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _dot1Controller.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _dot2Controller.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _dot3Controller.repeat(reverse: true);

    // ③ Auth check + minimum display time run concurrently
    final results = await Future.wait([
      _checkAuth(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    if (!mounted) return;

    // ④ Fade out then navigate
    await _exitController.forward();
    if (!mounted) return;

    _navigate(results[0] as String);
  }

  /*Future<String> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.tokenKey);
    final role  = prefs.getString(ApiConfig.userRoleKey);

    if (token == null) return '/login';
    switch (role) {
      case 'GUARD': return '/guard/home';
      case 'ADMIN': return '/admin/home';
      default:      return '/student/home';
    }
  }*/
  Future<String> _checkAuth() async {
  // TEMP: skip auth check, go straight to student shell
  return '/student/home';
  }

  void _navigate(String route) => context.go(route);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _exitOpacity,
        child: Stack(
          children: [
            // ── Background watermark ─────────────────────────────────────────
            const Center(
              child: Icon(
                LucideIcons.parkingCircle,
                size: 220,
                color: Color(0x0A4FC3F7), // AppColors.primary at ~4%
              ),
            ),

            // ── Logo + dots ──────────────────────────────────────────────────
            Center(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SmartPark',
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Accent underline
                            Container(
                              width: 48,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(102), // ~40%
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Pulsing dots
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PulsingDot(opacity: _dot1Opacity),
                        const SizedBox(width: 10),
                        _PulsingDot(opacity: _dot2Opacity),
                        const SizedBox(width: 10),
                        _PulsingDot(opacity: _dot3Opacity),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing dot
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingDot extends StatelessWidget {
  final Animation<double> opacity;

  const _PulsingDot({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
