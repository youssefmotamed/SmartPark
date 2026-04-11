// auth_provider.dart — Auth state management: login, register, logout, session restore
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/base_api_service.dart';
import '../services/profile_service.dart';

/// Manages authentication state for the entire app.
///
/// Holds the current [User], exposes login / register / logout actions,
/// and handles token persistence via [SharedPreferences].
class AuthProvider extends ChangeNotifier {
  final AuthService    _authService    = AuthService();
  final ProfileService _profileService = ProfileService();

  User?   _currentUser;
  bool    _isLoading = false;
  String? _error;

  /// The currently authenticated user, or null if not logged in.
  User? get currentUser => _currentUser;

  /// Whether an async auth operation is in progress.
  bool get isLoading => _isLoading;

  /// The last error message, or null if there is none.
  String? get error => _error;

  /// Whether a user session is active.
  bool get isLoggedIn => _currentUser != null;

  /// Role string of the current user ('STUDENT', 'GUARD', 'ADMIN'), or null.
  String? get role => _currentUser?.role;

  /// Clears the current error so the UI stops showing it.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Token storage helpers ──────────────────────────────────────────────────

  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    String role,
    int userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(ApiConfig.tokenKey,        accessToken),
      prefs.setString(ApiConfig.refreshTokenKey, refreshToken),
      prefs.setString(ApiConfig.userRoleKey,     role),
      prefs.setInt(ApiConfig.userIdKey,           userId),
    ]);
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(ApiConfig.tokenKey),
      prefs.remove(ApiConfig.refreshTokenKey),
      prefs.remove(ApiConfig.userRoleKey),
      prefs.remove(ApiConfig.userIdKey),
    ]);
  }

  // ── Auth actions ───────────────────────────────────────────────────────────

  /// Called by [SplashScreen] on app start.
  ///
  /// If a stored token exists, fetches the full profile to restore [_currentUser].
  /// On token expiry, attempts a silent refresh. Returns the initial route path.
  Future<String> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.tokenKey);
    final role  = prefs.getString(ApiConfig.userRoleKey);

    if (token == null || role == null) return '/login';

    // Token found — restore user state from the API.
    try {
      final profile = await _profileService.getProfile();
      _currentUser = profile.toUser();
      notifyListeners();
    } catch (_) {
      // Access token may be expired — attempt silent refresh.
      final refreshToken = prefs.getString(ApiConfig.refreshTokenKey);
      if (refreshToken != null) {
        try {
          final auth = await _authService.refresh(refreshToken);
          await _saveTokens(
            auth.accessToken,
            auth.refreshToken,
            auth.user.role,
            auth.user.id,
          );
          final profile = await _profileService.getProfile();
          _currentUser = profile.toUser();
          notifyListeners();
        } catch (_) {
          // Refresh also failed — session is dead.
          await _clearTokens();
          return '/login';
        }
      } else {
        await _clearTokens();
        return '/login';
      }
    }

    switch (role) {
      case 'GUARD': return '/guard/home';
      case 'ADMIN': return '/admin/home';
      default:      return '/student/home';
    }
  }

  /// Logs in with [email] and [password].
  ///
  /// On success: saves tokens and populates [currentUser].
  /// On failure: sets [error] with a user-friendly message.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authResponse = await _authService.login(
        email:    email,
        password: password,
      );

      await _saveTokens(
        authResponse.accessToken,
        authResponse.refreshToken,
        authResponse.user.role,
        authResponse.user.id,
      );

      if (authResponse.user.role == 'STUDENT') {
        // Fetch full profile — login response only has id, fullName, role.
        final profile = await _profileService.getProfile();
        _currentUser = profile.toUser();
      } else {
        // Guards and admins don't have a student profile endpoint.
        _currentUser = User(
          id:          authResponse.user.id,
          fullName:    authResponse.user.fullName,
          email:       '',
          studentId:   '',
          plateNumber: '',
          role:        authResponse.user.role,
          isActive:    true,
          createdAt:   DateTime.now(),
        );
      }
    } on ApiException catch (e) {
      _error = switch (e.statusCode) {
        401 => 'Invalid email or password.',
        422 => 'Your account has been deactivated.',
        _   => e.message,
      };
    } catch (_) {
      _error = 'Connection error. Check your network and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registers a new student account.
  ///
  /// Returns `true` on success — caller is responsible for navigating to login.
  /// On failure: sets [error] and returns `false`.
  Future<bool> register({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
    required String plateNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        fullName:    fullName,
        studentId:   studentId,
        email:       email,
        password:    password,
        plateNumber: plateNumber,
      );
      return true;
    } on ApiException catch (e) {
      _error = switch (e.statusCode) {
        409 => e.code == 'EMAIL_EXISTS'
            ? 'This email is already registered.'
            : 'This student ID is already registered.',
        400 => 'Please check your details and try again.',
        _   => e.message,
      };
      return false;
    } catch (_) {
      _error = 'Connection error. Check your network and try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs out: clears all stored tokens and resets user state.
  Future<void> logout() async {
    await _clearTokens();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
