// admin_service.dart — API service for all admin-role endpoints.
import '../models/admin_badge.dart';
import '../models/admin_user.dart';
import '../models/admin_violation.dart';
import '../models/analytics_summary.dart';
import '../models/guard_entry.dart';
import 'base_api_service.dart';

/// Handles all calls to the /admin/* endpoints.
class AdminService extends BaseApiService {

  // ── Users ────────────────────────────────────────────────────────────────

  /// Gets a paginated list of all users.
  ///
  /// Optional filters: [role] ('STUDENT'|'GUARD'|'ADMIN'), [search] (name/email),
  /// [isActive]. Returns the raw paginated data map so the provider can read
  /// both 'content' and pagination fields.
  /// Maps to GET /admin/users.
  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 20,
    String? role,
    String? search,
    bool? isActive,
  }) async {
    final buffer = StringBuffer('/admin/users?page=$page&size=$size');
    if (role != null) buffer.write('&role=$role');
    if (search != null && search.isNotEmpty) buffer.write('&search=$search');
    if (isActive != null) buffer.write('&isActive=$isActive');
    final response = await get(buffer.toString());
    return response['data'] as Map<String, dynamic>;
  }

  /// Creates a new user.
  ///
  /// For GUARD/ADMIN: provide fullName, email, password, role.
  /// For STUDENT: also include studentId and plateNumber.
  /// Maps to POST /admin/users.
  Future<AdminUser> createUser(Map<String, dynamic> userData) async {
    final response = await post('/admin/users', body: userData);
    return AdminUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Gets a single user by their database ID.
  /// Maps to GET /admin/users/{id}.
  Future<AdminUser> getUserById(int userId) async {
    final response = await get('/admin/users/$userId');
    return AdminUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Updates a user's [fullName] and/or [email]. Omit a field to leave it unchanged.
  /// Maps to PUT /admin/users/{id}.
  Future<AdminUser> updateUser(int userId, {
    String? fullName,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (email != null) body['email'] = email;
    final response = await put('/admin/users/$userId', body: body);
    return AdminUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Soft-deletes (deactivates) a user. Cannot be undone via the app.
  /// Maps to DELETE /admin/users/{id}.
  Future<void> deleteUser(int userId) async {
    await delete('/admin/users/$userId');
  }

  // ── Badges ────────────────────────────────────────────────────────────────

  /// Gets a paginated list of all badges.
  ///
  /// Optional filters: [status], [badgeType], [search] (student name/ID).
  /// Returns the raw paginated data map.
  /// Maps to GET /admin/badges.
  Future<Map<String, dynamic>> getBadges({
    int page = 0,
    int size = 20,
    String? status,
    String? badgeType,
    String? search,
  }) async {
    final buffer = StringBuffer('/admin/badges?page=$page&size=$size');
    if (status != null) buffer.write('&status=$status');
    if (badgeType != null) buffer.write('&badgeType=$badgeType');
    if (search != null && search.isNotEmpty) buffer.write('&search=$search');
    final response = await get(buffer.toString());
    return response['data'] as Map<String, dynamic>;
  }

  /// Updates badge fields (e.g. badgeType, violationCount, expiresAt).
  /// Maps to PUT /admin/badges/{id}.
  Future<AdminBadge> updateBadge(int badgeId, Map<String, dynamic> updates) async {
    final response = await put('/admin/badges/$badgeId', body: updates);
    return AdminBadge.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Manually suspends a badge for [suspensionDays] days with a [reason].
  /// Maps to POST /admin/badges/{id}/suspend.
  Future<AdminBadge> suspendBadge(int badgeId, {
    required int suspensionDays,
    required String reason,
  }) async {
    final response = await post('/admin/badges/$badgeId/suspend', body: {
      'suspensionDays': suspensionDays,
      'reason': reason,
    });
    return AdminBadge.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Lifts an active badge suspension immediately.
  /// Maps to POST /admin/badges/{id}/unsuspend.
  Future<AdminBadge> unsuspendBadge(int badgeId) async {
    final response = await post('/admin/badges/$badgeId/unsuspend');
    return AdminBadge.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  /// Gets real-time campus parking and user statistics for the admin dashboard.
  /// Maps to GET /admin/analytics/summary.
  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final response = await get('/admin/analytics/summary');
    return AnalyticsSummary.fromJson(response['data'] as Map<String, dynamic>);
  }

  // ── Violations ────────────────────────────────────────────────────────────

  /// Gets a paginated list of all recorded violations.
  ///
  /// Returns the raw paginated data map so the provider can read both
  /// 'content' and pagination fields.
  /// Maps to GET /admin/violations.
  Future<Map<String, dynamic>> getViolations({
    int page = 0,
    int size = 20,
  }) async {
    final response = await get('/admin/violations?page=$page&size=$size');
    return response['data'] as Map<String, dynamic>;
  }

  /// Parses a raw violations page map into a list of [AdminViolation] objects.
  List<AdminViolation> parseViolations(Map<String, dynamic> data) {
    final content = data['content'] as List<dynamic>;
    return content
        .map((e) => AdminViolation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Active reservations ───────────────────────────────────────────────────

  /// Gets the combined list of active student reservations and guest parking
  /// entries for the admin live-view. Same structure as the guard endpoint.
  /// Maps to GET /admin/reservations/active.
  Future<List<GuardEntry>> getActiveReservations() async {
    final response = await get('/admin/reservations/active');
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => GuardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Spots ────────────────────────────────────────────────────────────────

  /// Updates a spot's status directly (admin override, no audit log).
  ///
  /// [newStatus]: 'AVAILABLE', 'RESERVED', 'OCCUPIED', or 'UNAVAILABLE'.
  /// Maps to PATCH /admin/spots/{spotId}/status.
  Future<void> updateSpotStatus(int spotId, String newStatus) async {
    await patch('/admin/spots/$spotId/status', body: {'newStatus': newStatus});
  }

  // ── Rewards ───────────────────────────────────────────────────────────────

  /// Updates a reward's [pointsCost] and/or [isActive] flag.
  /// Omit a field to leave it unchanged.
  /// Maps to PUT /admin/rewards/{id}.
  Future<void> updateReward(int rewardId, {
    int? pointsCost,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (pointsCost != null) body['pointsCost'] = pointsCost;
    if (isActive != null) body['isActive'] = isActive;
    await put('/admin/rewards/$rewardId', body: body);
  }
}
