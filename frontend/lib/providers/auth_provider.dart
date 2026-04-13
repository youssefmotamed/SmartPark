// auth_provider.dart — Authentication state management (login, logout, session restore)
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/base_api_service.dart';

/// Manages authentication state across the app.
///
/// Login and register are stubbed out in Phase 0 and will be implemented
/// in Phase 1 once the auth API service is ready.
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  /// The currently authenticated user, or null if not logged in.
  User? get currentUser => _currentUser;

  /// Whether an async auth operation is in progress.
  bool get isLoading => _isLoading;

  /// The last error message, or null if no error.
  String? get error => _error;

  /// Whether a user is currently logged in.
  bool get isLoggedIn => _currentUser != null;

  /// The role string of the current user ('STUDENT', 'GUARD', 'ADMIN'), or null.
  String? get role => _currentUser?.role;

  /// Checks SharedPreferences for a stored token and role to restore session state.
  ///
  /// Does not fetch the user profile — that is added in Phase 1.
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    // Phase 0: just confirm SharedPreferences is accessible.
    // The SplashScreen reads tokenKey and userRoleKey directly for routing.
    // Profile fetch will populate _currentUser in Phase 1.
    await prefs.reload();

    _isLoading = false;
    notifyListeners();
  }

  /// Authenticates the user with [email] and [password].
  ///
  /// Stores the JWT tokens and user info in SharedPreferences on success.
  /// Sets [error] on failure.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await AuthService().login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConfig.tokenKey,        result.accessToken);
      await prefs.setString(ApiConfig.refreshTokenKey, result.refreshToken);
      await prefs.setString(ApiConfig.userRoleKey,     result.role);
      await prefs.setString(ApiConfig.userIdKey,       result.userId.toString());
      debugPrint('Token saved: ${result.accessToken.substring(0, 20)}...');
      debugPrint('Role saved: ${result.role}');
      _currentUser = User(
        id:          result.userId,
        fullName:    result.fullName,
        email:       email,
        studentId:   '',
        plateNumber: '',
        role:        result.role,
        isActive:    true,
        createdAt:   DateTime.now(),
      );
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Connection error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registers a new student account.
  ///
  /// Implemented in Phase 1.
  Future<void> register(
    String fullName,
    String studentId,
    String email,
    String password,
    String plateNumber,
  ) async {
    throw UnimplementedError('register() will be implemented in Phase 1');
  }

  /// Clears all stored credentials and resets local state.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(ApiConfig.tokenKey),
      prefs.remove(ApiConfig.refreshTokenKey),
      prefs.remove(ApiConfig.userRoleKey),
      prefs.remove(ApiConfig.userIdKey),
    ]);
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
