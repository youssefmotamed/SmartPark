// main.dart — App entry point: providers, theme, and GoRouter configuration
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

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

/// Splash screen that resolves the initial route based on stored credentials.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay allows the widget tree to settle before navigation.
    Future.delayed(const Duration(milliseconds: 300), _redirect);
  }

  Future<void> _redirect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.tokenKey);
    final role = prefs.getString(ApiConfig.userRoleKey);

    if (!mounted) return;

    if (token == null) {
      context.go('/login');
      return;
    }

    switch (role) {
      case 'GUARD':
        context.go('/guard/home');
      case 'ADMIN':
        context.go('/admin/home');
      default:
        context.go('/student/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Returns a minimal placeholder scaffold used for routes not yet implemented.
Widget _placeholder(String name) {
  return Scaffold(
    appBar: AppBar(title: Text(name)),
    body: Center(child: Text(name)),
  );
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
    GoRoute(
      path: '/student/home',
      builder: (_, _) => _placeholder('Student Home'),
    ),
    GoRoute(
      path: '/guard/home',
      builder: (_, _) => _placeholder('Guard Home'),
    ),
    GoRoute(
      path: '/admin/home',
      builder: (_, _) => _placeholder('Admin Home'),
    ),
  ],
);
