// admin_provider.dart — Manages all admin state for SmartPark Phase 6:
// analytics, users, badges, violations, and reward/spot management.
import 'package:flutter/material.dart';
import '../models/admin_badge.dart';
import '../models/admin_user.dart';
import '../models/admin_violation.dart';
import '../models/analytics_summary.dart';
import '../services/admin_service.dart';
import '../services/base_api_service.dart';

/// Manages state for all admin-role screens (Phase 6).
///
/// Handles:
/// - Analytics summary for S28
/// - Paginated users list + CRUD for S29/S30
/// - Paginated badges list + suspend/unsuspend for S31
/// - Paginated violations list for S32
/// - Reward and spot status updates
class AdminProvider extends ChangeNotifier {

  static const int _pageSize = 20;

  // ── Analytics ─────────────────────────────────────────────────────────────
  AnalyticsSummary? _analytics;
  bool              _isLoadingAnalytics = false;
  String?           _analyticsError;

  AnalyticsSummary? get analytics           => _analytics;
  bool              get isLoadingAnalytics  => _isLoadingAnalytics;
  String?           get analyticsError      => _analyticsError;

  // ── Users ─────────────────────────────────────────────────────────────────
  List<AdminUser> _users            = [];
  bool            _isLoadingUsers   = false;
  String?         _usersError;
  int             _usersTotal       = 0;
  int             _usersPage        = 0;
  bool            _usersHasMore     = false;
  String?         _usersRoleFilter;
  String?         _usersSearchQuery;

  List<AdminUser> get users           => _users;
  bool            get isLoadingUsers  => _isLoadingUsers;
  String?         get usersError      => _usersError;
  int             get usersTotal      => _usersTotal;
  bool            get usersHasMore    => _usersHasMore;

  // ── Selected user ─────────────────────────────────────────────────────────
  AdminUser? _selectedUser;
  bool       _isLoadingUser = false;

  AdminUser? get selectedUser      => _selectedUser;
  bool       get isLoadingUser     => _isLoadingUser;

  // ── Badges ────────────────────────────────────────────────────────────────
  List<AdminBadge> _badges             = [];
  bool             _isLoadingBadges    = false;
  String?          _badgesError;
  int              _badgesTotal        = 0;
  int              _badgesPage         = 0;
  bool             _badgesHasMore      = false;
  String?          _badgesStatusFilter;

  List<AdminBadge> get badges          => _badges;
  bool             get isLoadingBadges => _isLoadingBadges;
  String?          get badgesError     => _badgesError;
  int              get badgesTotal     => _badgesTotal;
  bool             get badgesHasMore   => _badgesHasMore;

  // ── Violations ────────────────────────────────────────────────────────────
  List<AdminViolation> _violations            = [];
  bool                 _isLoadingViolations   = false;
  String?              _violationsError;
  int                  _violationsTotal       = 0;
  int                  _violationsPage        = 0;
  bool                 _violationsHasMore     = false;

  List<AdminViolation> get violations           => _violations;
  bool                 get isLoadingViolations  => _isLoadingViolations;
  String?              get violationsError      => _violationsError;
  int                  get violationsTotal      => _violationsTotal;
  bool                 get violationsHasMore    => _violationsHasMore;

  // ── General operation state ───────────────────────────────────────────────
  bool    _isOperating    = false;
  String? _operationError;

  bool    get isOperating    => _isOperating;
  String? get operationError => _operationError;

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// Loads real-time campus analytics. Call when S28 (admin home) opens.
  Future<void> loadAnalytics() async {
    _isLoadingAnalytics = true;
    _analyticsError     = null;
    notifyListeners();
    try {
      _analytics = await AdminService().getAnalyticsSummary();
    } on ApiException catch (e) {
      _analyticsError = e.toString();
    } catch (_) {
      _analyticsError = 'Failed to load analytics';
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  /// Loads the first page of users, resetting pagination.
  ///
  /// Optional [role] filter ('STUDENT'|'GUARD'|'ADMIN') and [search] query.
  /// Call when S29 (users list) opens or when filters change.
  Future<void> loadUsers({String? role, String? search}) async {
    _isLoadingUsers   = true;
    _usersError       = null;
    _usersPage        = 0;
    _users            = [];
    _usersRoleFilter  = role;
    _usersSearchQuery = search;
    notifyListeners();
    try {
      final data = await AdminService().getUsers(
        page:   0,
        size:   _pageSize,
        role:   role,
        search: search,
      );
      final content = data['content'] as List<dynamic>;
      _users      = content
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList();
      _usersTotal   = data['totalElements'] as int;
      _usersHasMore = _users.length < _usersTotal;
    } on ApiException catch (e) {
      _usersError = e.toString();
    } catch (_) {
      _usersError = 'Failed to load users';
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  /// Loads the next page of users and appends to [users].
  /// No-op if already loading or no more pages.
  Future<void> loadMoreUsers() async {
    if (_isOperating || !_usersHasMore) return;
    _isOperating = true;
    notifyListeners();
    try {
      final data = await AdminService().getUsers(
        page:   _usersPage + 1,
        size:   _pageSize,
        role:   _usersRoleFilter,
        search: _usersSearchQuery,
      );
      final content = data['content'] as List<dynamic>;
      final newItems = content
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList();
      _users.addAll(newItems);
      _usersPage    = data['number'] as int;
      _usersHasMore = _users.length < _usersTotal;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Loads a single user by ID. Sets [selectedUser].
  /// Call when S30 (user detail) opens.
  Future<void> loadUser(int userId) async {
    _isLoadingUser = true;
    _selectedUser  = null;
    notifyListeners();
    try {
      _selectedUser = await AdminService().getUserById(userId);
    } on ApiException catch (e) {
      _operationError = e.toString();
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  /// Creates a new user. Returns the created [AdminUser] on success, null on failure.
  ///
  /// Refreshes the users list on success. Check [operationError] on failure.
  Future<AdminUser?> createUser(Map<String, dynamic> userData) async {
    _isOperating    = true;
    _operationError = null;
    notifyListeners();
    try {
      final result = await AdminService().createUser(userData);
      await loadUsers(role: _usersRoleFilter, search: _usersSearchQuery);
      return result;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return null;
    } catch (_) {
      _operationError = 'Failed to create user';
      return null;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Updates a user's name and/or email. Returns true on success.
  ///
  /// Updates [selectedUser] and the matching entry in [users] in-place.
  Future<bool> updateUser(int userId, {String? fullName, String? email}) async {
    _isOperating    = true;
    _operationError = null;
    notifyListeners();
    try {
      final updated = await AdminService().updateUser(
        userId,
        fullName: fullName,
        email:    email,
      );
      _selectedUser = updated;
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) _users[idx] = updated;
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to update user';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Soft-deletes (deactivates) a user. Returns true on success.
  ///
  /// Refreshes the users list on success.
  Future<bool> deleteUser(int userId) async {
    _isOperating    = true;
    _operationError = null;
    notifyListeners();
    try {
      await AdminService().deleteUser(userId);
      await loadUsers(role: _usersRoleFilter, search: _usersSearchQuery);
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to deactivate user';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ── Badges ────────────────────────────────────────────────────────────────

  /// Loads the first page of badges, resetting pagination.
  ///
  /// Optional [status] filter ('ACTIVE'|'SUSPENDED'|'EXPIRED') and [search] query.
  /// Call when S31 (badges list) opens or when filters change.
  Future<void> loadBadges({String? status, String? search}) async {
    _isLoadingBadges    = true;
    _badgesError        = null;
    _badgesPage         = 0;
    _badges             = [];
    _badgesStatusFilter = status;
    notifyListeners();
    try {
      final data = await AdminService().getBadges(
        page:   0,
        size:   _pageSize,
        status: status,
        search: search,
      );
      final content = data['content'] as List<dynamic>;
      _badges       = content
          .map((e) => AdminBadge.fromJson(e as Map<String, dynamic>))
          .toList();
      _badgesTotal   = data['totalElements'] as int;
      _badgesHasMore = _badges.length < _badgesTotal;
    } on ApiException catch (e) {
      _badgesError = e.toString();
    } catch (_) {
      _badgesError = 'Failed to load badges';
    } finally {
      _isLoadingBadges = false;
      notifyListeners();
    }
  }

  /// Loads the next page of badges and appends to [badges].
  /// No-op if already loading or no more pages.
  Future<void> loadMoreBadges() async {
    if (_isLoadingBadges || !_badgesHasMore) return;
    _isLoadingBadges = true;
    notifyListeners();
    try {
      final data = await AdminService().getBadges(
        page:   _badgesPage + 1,
        size:   _pageSize,
        status: _badgesStatusFilter,
      );
      final content = data['content'] as List<dynamic>;
      final newItems = content
          .map((e) => AdminBadge.fromJson(e as Map<String, dynamic>))
          .toList();
      _badges.addAll(newItems);
      _badgesPage    = data['number'] as int;
      _badgesHasMore = _badges.length < _badgesTotal;
    } finally {
      _isLoadingBadges = false;
      notifyListeners();
    }
  }

  /// Manually suspends a badge. Returns true on success.
  ///
  /// Updates the matching badge in [badges] in-place on success.
  Future<bool> suspendBadge(int badgeId, {
    required int    suspensionDays,
    required String reason,
  }) async {
    _isOperating    = true;
    _operationError = null;
    notifyListeners();
    try {
      final updated = await AdminService().suspendBadge(
        badgeId,
        suspensionDays: suspensionDays,
        reason:         reason,
      );
      final idx = _badges.indexWhere((b) => b.badgeId == badgeId);
      if (idx != -1) _badges[idx] = updated;
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to suspend badge';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  /// Lifts a badge suspension immediately. Returns true on success.
  ///
  /// Updates the matching badge in [badges] in-place on success.
  Future<bool> unsuspendBadge(int badgeId) async {
    _isOperating    = true;
    _operationError = null;
    notifyListeners();
    try {
      final updated = await AdminService().unsuspendBadge(badgeId);
      final idx = _badges.indexWhere((b) => b.badgeId == badgeId);
      if (idx != -1) _badges[idx] = updated;
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to unsuspend badge';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ── Violations ────────────────────────────────────────────────────────────

  /// Loads the first page of violations, resetting pagination.
  /// Call when S32 (violations list) opens.
  Future<void> loadViolations() async {
    _isLoadingViolations = true;
    _violationsError     = null;
    _violationsPage      = 0;
    _violations          = [];
    notifyListeners();
    try {
      final data = await AdminService().getViolations(page: 0, size: _pageSize);
      final content = data['content'] as List<dynamic>;
      _violations       = content
          .map((e) => AdminViolation.fromJson(e as Map<String, dynamic>))
          .toList();
      _violationsTotal   = data['totalElements'] as int;
      _violationsHasMore = _violations.length < _violationsTotal;
    } on ApiException catch (e) {
      _violationsError = e.toString();
    } catch (_) {
      _violationsError = 'Failed to load violations';
    } finally {
      _isLoadingViolations = false;
      notifyListeners();
    }
  }

  /// Loads the next page of violations and appends to [violations].
  /// No-op if already loading or no more pages.
  Future<void> loadMoreViolations() async {
    if (_isLoadingViolations || !_violationsHasMore) return;
    _isLoadingViolations = true;
    notifyListeners();
    try {
      final data = await AdminService().getViolations(
        page: _violationsPage + 1,
        size: _pageSize,
      );
      final content = data['content'] as List<dynamic>;
      final newItems = content
          .map((e) => AdminViolation.fromJson(e as Map<String, dynamic>))
          .toList();
      _violations.addAll(newItems);
      _violationsPage    = data['number'] as int;
      _violationsHasMore = _violations.length < _violationsTotal;
    } finally {
      _isLoadingViolations = false;
      notifyListeners();
    }
  }

  // ── Rewards ───────────────────────────────────────────────────────────────

  /// Updates a reward's [pointsCost] and/or [isActive] flag.
  /// Returns true on success.
  Future<bool> updateReward(int rewardId, {int? pointsCost, bool? isActive}) async {
    _isOperating    = true;
    _operationError = null;
    notifyListeners();
    try {
      await AdminService().updateReward(
        rewardId,
        pointsCost: pointsCost,
        isActive:   isActive,
      );
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to update reward';
      return false;
    } finally {
      _isOperating = false;
      notifyListeners();
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Clears the current operation error. Call before opening a form or action sheet.
  void clearOperationError() {
    _operationError = null;
    notifyListeners();
  }

  /// Resets all state. Call on logout.
  void reset() {
    _analytics           = null;
    _users               = [];
    _badges              = [];
    _violations          = [];
    _selectedUser        = null;
    _isLoadingAnalytics  = false;
    _isLoadingUsers      = false;
    _isLoadingBadges     = false;
    _isLoadingViolations = false;
    _isLoadingUser       = false;
    _isOperating         = false;
    _analyticsError      = null;
    _usersError          = null;
    _badgesError         = null;
    _violationsError     = null;
    _operationError      = null;
    _usersPage           = 0;
    _badgesPage          = 0;
    _violationsPage      = 0;
    _usersTotal          = 0;
    _badgesTotal         = 0;
    _violationsTotal     = 0;
    _usersHasMore        = false;
    _badgesHasMore       = false;
    _violationsHasMore   = false;
    _usersRoleFilter     = null;
    _usersSearchQuery    = null;
    _badgesStatusFilter  = null;
    notifyListeners();
  }
}
