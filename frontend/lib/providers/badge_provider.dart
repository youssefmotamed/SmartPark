// badge_provider.dart — Manages badge list, detail, and all badge operations for Phase 5
import 'package:flutter/material.dart';
import '../models/badge_detail.dart';
import '../models/badge_reservation.dart';
import '../models/badge_summary.dart';
import '../services/badge_service.dart';
import '../services/base_api_service.dart';
import '../services/profile_service.dart';

/// Manages state for Phase 5 Badge & Carpool screens (S15–S20).
///
/// Handles:
/// - Badge list for S15 (via GET /profile/badges)
/// - Selected badge detail + active reservation for S16
/// - Create, invite, add-car, and accept operations
/// - Separate error fields per operation so screens don't interfere
class BadgeProvider extends ChangeNotifier {

  // ── Badge list (S15) ──────────────────────────────────────────────────────
  List<BadgeSummary> _badges          = [];
  bool               _isLoadingBadges = false;
  String?            _badgesError;

  // ── Selected badge detail (S16) ───────────────────────────────────────────
  BadgeDetail? _selectedBadge;
  bool         _isLoadingDetail = false;
  String?      _detailError;

  // ── Badge reservation (S16) ───────────────────────────────────────────────
  BadgeReservation? _badgeReservation;
  bool              _isLoadingReservation = false;
  bool              _hasNoReservation     = false;

  // ── Mutation flags ────────────────────────────────────────────────────────
  bool    _isCreating   = false;
  bool    _isInviting   = false;
  bool    _isAddingCar  = false;
  bool    _isAccepting  = false;
  String? _operationError;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<BadgeSummary> get badges               => _badges;
  bool               get isLoadingBadges      => _isLoadingBadges;
  String?            get badgesError          => _badgesError;

  BadgeDetail?       get selectedBadge        => _selectedBadge;
  bool               get isLoadingDetail      => _isLoadingDetail;
  String?            get detailError          => _detailError;

  BadgeReservation?  get badgeReservation     => _badgeReservation;
  bool               get isLoadingReservation => _isLoadingReservation;
  bool               get hasNoReservation     => _hasNoReservation;

  bool               get isCreating           => _isCreating;
  bool               get isInviting           => _isInviting;
  bool               get isAddingCar          => _isAddingCar;
  bool               get isAccepting          => _isAccepting;
  String?            get operationError       => _operationError;

  /// The ACTIVE badge from the list, or null if none exists.
  BadgeSummary? get activeBadge =>
      _badges.where((b) => b.status == 'ACTIVE').firstOrNull;

  /// Whether the selected badge has a creator member (canInvite == true).
  /// The screen compares this member's userId against the current user's ID
  /// to decide whether to show invite/add-car controls.
  bool get isCreatorOfSelected => _selectedBadge?.creator != null;

  // ── Badge list ────────────────────────────────────────────────────────────

  /// Loads all badges the student belongs to via GET /profile/badges.
  /// Call when S15 (Badges screen) opens.
  Future<void> loadBadges() async {
    _isLoadingBadges = true;
    _badgesError     = null;
    notifyListeners();
    try {
      _badges = await ProfileService().getBadges();
    } on ApiException catch (e) {
      _badgesError = e.toString();
    } catch (_) {
      _badgesError = 'Failed to load badges';
    } finally {
      _isLoadingBadges = false;
      notifyListeners();
    }
  }

  // ── Badge detail ──────────────────────────────────────────────────────────

  /// Loads full badge detail and the active reservation in parallel.
  ///
  /// Resets [selectedBadge] and [badgeReservation] before fetching.
  /// Call when S16 (Badge Detail screen) opens.
  Future<void> loadBadgeDetail(int badgeId) async {
    _isLoadingDetail  = true;
    _detailError      = null;
    _selectedBadge    = null;
    _badgeReservation = null;
    _hasNoReservation = false;
    notifyListeners();
    try {
      await Future.wait([
        BadgeService()
            .getBadgeDetail(badgeId)
            .then((d) => _selectedBadge = d),
        _loadBadgeReservationInternal(badgeId),
      ]);
    } on ApiException catch (e) {
      _detailError = e.toString();
    } catch (_) {
      _detailError = 'Failed to load badge details';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Internal: fetches the active reservation for [badgeId].
  ///
  /// A 404 is normal (badge may have no active reservation) and sets
  /// [hasNoReservation] to true. Other errors are silently swallowed so
  /// the reservation section simply stays empty rather than blocking the detail view.
  Future<void> _loadBadgeReservationInternal(int badgeId) async {
    _isLoadingReservation = true;
    try {
      _badgeReservation = await BadgeService().getBadgeReservation(badgeId);
      _hasNoReservation = false;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _hasNoReservation = true;
        _badgeReservation = null;
      }
    } finally {
      _isLoadingReservation = false;
    }
  }

  // ── Create badge ──────────────────────────────────────────────────────────

  /// Creates a new badge and reloads the badge list on success.
  ///
  /// Returns the created [BadgeDetail] on success, or null on failure.
  /// Check [operationError] for the failure reason.
  Future<BadgeDetail?> createBadge({
    required String badgeType,
    required int    semesterNumber,
    required int    semesterYear,
  }) async {
    _isCreating     = true;
    _operationError = null;
    notifyListeners();
    try {
      final result = await BadgeService().createBadge(
        badgeType:      badgeType,
        semesterNumber: semesterNumber,
        semesterYear:   semesterYear,
      );
      await loadBadges();
      return result;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return null;
    } catch (_) {
      _operationError = 'Failed to create badge';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // ── Invite member ─────────────────────────────────────────────────────────

  /// Invites a student to join a carpool badge by their university student ID.
  ///
  /// Returns true on success and refreshes [selectedBadge] with the updated data.
  /// Check [operationError] on failure.
  Future<bool> inviteMember(int badgeId, String studentId) async {
    _isInviting     = true;
    _operationError = null;
    notifyListeners();
    try {
      final updated = await BadgeService().inviteMember(
        badgeId:   badgeId,
        studentId: studentId,
      );
      _selectedBadge = updated;
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to send invitation';
      return false;
    } finally {
      _isInviting = false;
      notifyListeners();
    }
  }

  // ── Add car ───────────────────────────────────────────────────────────────

  /// Adds an extra car to an accepted member's carpool slot.
  ///
  /// [forUserId] is the DB user ID of the accepted member who owns the slot.
  /// Returns true on success and refreshes [selectedBadge] with the updated data.
  Future<bool> addCar({
    required int    badgeId,
    required String plateNumber,
    required int    forUserId,
    String?         carModel,
  }) async {
    _isAddingCar    = true;
    _operationError = null;
    notifyListeners();
    try {
      final updated = await BadgeService().addCar(
        badgeId:     badgeId,
        plateNumber: plateNumber,
        forUserId:   forUserId,
        carModel:    carModel,
      );
      _selectedBadge = updated;
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to add car';
      return false;
    } finally {
      _isAddingCar = false;
      notifyListeners();
    }
  }

  // ── Accept invitation ─────────────────────────────────────────────────────

  /// Accepts a pending carpool invitation for the current student.
  ///
  /// Returns true on success and reloads the badge list so S15 reflects
  /// the newly joined badge.
  Future<bool> acceptInvitation(int badgeId) async {
    _isAccepting    = true;
    _operationError = null;
    notifyListeners();
    try {
      await BadgeService().acceptInvitation(badgeId);
      await loadBadges();
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to accept invitation';
      return false;
    } finally {
      _isAccepting = false;
      notifyListeners();
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Clears the operation error. Call before opening a form or action sheet.
  void clearOperationError() {
    _operationError = null;
    notifyListeners();
  }

  /// Resets all state. Call on logout.
  void reset() {
    _badges               = [];
    _selectedBadge        = null;
    _badgeReservation     = null;
    _hasNoReservation     = false;
    _isLoadingBadges      = false;
    _isLoadingDetail      = false;
    _isLoadingReservation = false;
    _isCreating           = false;
    _isInviting           = false;
    _isAddingCar          = false;
    _isAccepting          = false;
    _badgesError          = null;
    _detailError          = null;
    _operationError       = null;
    notifyListeners();
  }
}
