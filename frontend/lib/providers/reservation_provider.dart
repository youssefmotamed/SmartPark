// reservation_provider.dart — Manages reservation state for SmartPark students
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reservation_response.dart';
import '../models/create_reservation_request.dart';
import '../services/reservation_service.dart';
import '../services/base_api_service.dart';

class ReservationProvider extends ChangeNotifier {
  final ReservationService _service = ReservationService();

  // ── Active reservation ────────────────────────────────────────────────────
  ReservationResponse? _activeReservation;
  bool                 _isLoadingActive = false;
  String?              _activeError;

  // ── Create / cancel ───────────────────────────────────────────────────────
  bool    _isCreating  = false;
  String? _createError;

  // ── History ───────────────────────────────────────────────────────────────
  List<ReservationResponse> _history          = [];
  bool                      _isLoadingHistory = false;
  String?                   _historyError;
  int                       _currentPage      = 0;
  bool                      _hasMorePages     = false;
  String?                   _historyFilter;

  // ── Countdown timer ───────────────────────────────────────────────────────
  Timer?    _countdownTimer;
  Duration? _timeRemaining;

  // ── Getters ───────────────────────────────────────────────────────────────
  ReservationResponse?      get activeReservation    => _activeReservation;
  bool                      get isLoadingActive      => _isLoadingActive;
  String?                   get activeError          => _activeError;
  bool                      get isCreating           => _isCreating;
  String?                   get createError          => _createError;
  List<ReservationResponse> get history              => _history;
  bool                      get isLoadingHistory     => _isLoadingHistory;
  String?                   get historyError         => _historyError;
  bool                      get hasMorePages         => _hasMorePages;
  String?                   get historyFilter        => _historyFilter;
  Duration?                 get timeRemaining        => _timeRemaining;
  bool                      get hasActiveReservation => _activeReservation != null;

  void clearCreateError() {
    _createError = null;
    notifyListeners();
  }

  // ── Active reservation ────────────────────────────────────────────────────

  /// Fetches the current active reservation. Sets to null on 404.
  Future<void> fetchActiveReservation() async {
    _isLoadingActive = true;
    _activeError = null;
    notifyListeners();
    try {
      _activeReservation = await _service.getActiveReservation();
      _startCountdownIfNeeded();
    } on ApiException catch (e) {
      _activeError = e.message;
    } catch (_) {
      _activeError = 'Failed to load reservation.';
    } finally {
      _isLoadingActive = false;
      notifyListeners();
    }
  }

  /// Creates a reservation. Returns true on success, false on failure.
  /// Check [createError] for the failure reason.
  Future<bool> createReservation(CreateReservationRequest request) async {
    _isCreating  = true;
    _createError = null;
    notifyListeners();
    try {
      _activeReservation = await _service.createReservation(request);
      _startCountdownIfNeeded();
      return true;
    } on ApiException catch (e) {
      _createError = _mapCreateError(e);
      return false;
    } catch (_) {
      _createError = 'Connection error. Please try again.';
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  /// Cancels the active reservation. Returns true on success.
  Future<bool> cancelReservation() async {
    if (_activeReservation == null) return false;
    _isCreating  = true;
    _createError = null;
    notifyListeners();
    try {
      await _service.cancelReservation(_activeReservation!.id);
      _stopCountdown();
      _activeReservation = null;
      return true;
    } on ApiException catch (e) {
      _createError = e.message;
      return false;
    } catch (_) {
      _createError = 'Connection error. Please try again.';
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  /// Fetches history from page 0, replacing any existing list.
  Future<void> fetchHistory({String? status}) async {
    _historyFilter    = status;
    _currentPage      = 0;
    _history          = [];
    _isLoadingHistory = true;
    _historyError     = null;
    notifyListeners();
    try {
      final page = await _service.getHistory(page: 0, status: status);
      _history      = page.content;
      _hasMorePages = page.hasMore;
    } on ApiException catch (e) {
      _historyError = e.message;
    } catch (_) {
      _historyError = 'Failed to load history.';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Appends the next page to the existing history list.
  Future<void> loadMoreHistory() async {
    if (!_hasMorePages || _isLoadingHistory) return;
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final page = await _service.getHistory(
        page: _currentPage + 1,
        status: _historyFilter,
      );
      _history.addAll(page.content);
      _hasMorePages = page.hasMore;
      _currentPage++;
    } catch (_) {
      // Silently fail on load-more — existing data stays visible
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // ── Countdown timer ───────────────────────────────────────────────────────

  /// Starts a 1-second countdown if the active reservation has an expiresAt.
  /// Only runs for ACTIVE status — ENTERED reservations never expire.
  void _startCountdownIfNeeded() {
    _stopCountdown();
    final res = _activeReservation;
    if (res == null || res.expiresAt == null || !res.isActive) return;

    _timeRemaining = res.timeRemaining;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final expiry = _activeReservation?.expiresAt;
      if (expiry == null) { _stopCountdown(); return; }

      _timeRemaining = expiry.difference(DateTime.now());
      if (_timeRemaining!.isNegative) {
        _timeRemaining     = Duration.zero;
        _activeReservation = null;
        _stopCountdown();
      }
      notifyListeners();
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// Call after the guard scans entry — stops the expiry timer and refreshes state.
  void onEntryScanned() {
    _stopCountdown();
    _timeRemaining = null;
    fetchActiveReservation();
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  String _mapCreateError(ApiException e) {
    if (e.statusCode == 404) return 'Spot or badge not found.';
    if (e.statusCode == 422) {
      return switch (e.code) {
        'BADGE_SUSPENDED'           => 'Your badge is currently suspended.',
        'SPOT_NOT_AVAILABLE'        => 'This spot is no longer available.',
        'TOO_FAR'                   => 'You are too far from campus to reserve.',
        'SAME_SPOT_RESTRICTION'     => 'You cannot re-reserve the same spot.',
        'ZONE_ACCESS_DENIED'        => 'Your badge type cannot access this zone.',
        'ACTIVE_RESERVATION_EXISTS' => 'You already have an active reservation.',
        _                           => e.message,
      };
    }
    return e.message;
  }

  @override
  void dispose() {
    _stopCountdown();
    super.dispose();
  }
}
