// main.dart — App entry point: providers, theme, and GoRouter configuration
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/guard_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/points_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/rewards_provider.dart';
import 'providers/spots_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/student/active_reservation_screen.dart';
import 'screens/student/reservation_cancelled_screen.dart';
import 'screens/student/points_balance_screen.dart';
import 'screens/student/points_history_screen.dart';
import 'screens/student/rewards_screen.dart';
import 'screens/student/advance_reservation_screen.dart';
import 'screens/student/badge_list_screen.dart';
import 'screens/student/badge_detail_screen.dart';
import 'screens/student/create_badge_screen.dart';
import 'screens/student/invite_member_screen.dart';
import 'screens/student/add_car_screen.dart';
import 'screens/student/invitation_screen.dart';
import 'screens/student/reservation_history_screen.dart';
import 'screens/student/student_shell.dart';
import 'screens/guard/guard_shell.dart';
import 'screens/shared/notification_screen.dart';
import 'screens/guard/qr_scanner_screen.dart';
import 'screens/guard/scan_result_screen.dart';
import 'screens/admin/admin_shell.dart';

void main() {
  runApp(const SmartParkApp());
}

/// Root widget — wires up providers, theme, and router.
class SmartParkApp extends StatelessWidget {
  const SmartParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => GuardProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PointsProvider()),
        ChangeNotifierProvider(create: (_) => RewardsProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
      ],
      child: MaterialApp.router(
        title: 'SmartPark',
        theme: AppTheme.darkTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Application router — all routes are defined here.
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, _) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, _) => const RegisterScreen(),
    ),

    // ── Student shell ────────────────────────────────────────────────────────
    // StudentShell manages its own 4-tab IndexedStack internally.
    // Additional student sub-routes (reservation, QR, etc.) will be added
    // here as full-screen GoRoutes in Phase 1–4.
    GoRoute(
      path: '/student/home',
      builder: (_, _) => const StudentShell(),
    ),
    GoRoute(
      path: '/student/reservation',
      builder: (_, _) => const ActiveReservationScreen(),
    ),
    GoRoute(
      path: '/student/history',
      builder: (_, _) => const ReservationHistoryScreen(),
    ),
    GoRoute(
      path: '/student/reservation/cancelled',
      builder: (_, _) => const ReservationCancelledScreen(),
    ),
    GoRoute(
      path: '/student/notifications',
      builder: (_, _) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/student/points',
      builder: (_, _) => const PointsBalanceScreen(),
    ),
    GoRoute(
      path: '/student/points/history',
      builder: (_, _) => const PointsHistoryScreen(),
    ),
    GoRoute(
      path: '/student/rewards',
      builder: (_, _) => const RewardsScreen(),
    ),
    GoRoute(
      path: '/student/advance-reservation',
      builder: (_, _) => const AdvanceReservationScreen(),
    ),
    GoRoute(
      path: '/student/badges',
      builder: (_, _) => const BadgeListScreen(),
    ),
    GoRoute(
      path: '/student/badges/create',
      builder: (_, _) => const CreateBadgeScreen(),
    ),
    GoRoute(
      path: '/student/badges/:badgeId',
      builder: (_, state) => BadgeDetailScreen(
        badgeId: int.parse(state.pathParameters['badgeId']!),
      ),
    ),
    GoRoute(
      path: '/student/badges/:badgeId/invite',
      builder: (_, state) => InviteMemberScreen(
        badgeId: int.parse(state.pathParameters['badgeId']!),
      ),
    ),
    GoRoute(
      path: '/student/badges/:badgeId/add-car',
      builder: (_, state) => AddCarScreen(
        badgeId: int.parse(state.pathParameters['badgeId']!),
      ),
    ),
    GoRoute(
      path: '/student/badges/:badgeId/accept',
      builder: (_, state) => InvitationScreen(
        badgeId: int.parse(state.pathParameters['badgeId']!),
      ),
    ),

    // ── Guard shell ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/guard/home',
      builder: (_, _) => const GuardShell(),
    ),
    GoRoute(
      path: '/guard/scanner',
      builder: (_, _) => const QRScannerScreen(),
    ),
    GoRoute(
      path: '/guard/result',
      builder: (_, _) => const ScanResultScreen(),
    ),
    GoRoute(
      path: '/guard/notifications',
      builder: (_, _) => const NotificationScreen(),
    ),

    // ── Admin shell ──────────────────────────────────────────────────────────
    // AdminShell manages its own 3-tab IndexedStack internally.
    // Admin sub-routes (users, badges, analytics) added in Phase 6.
    GoRoute(
      path: '/admin/home',
      builder: (_, _) => const AdminShell(),
    ),
  ],
);
