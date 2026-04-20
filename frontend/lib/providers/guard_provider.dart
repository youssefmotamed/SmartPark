// guard_provider.dart — Manages all guard state for SmartPark:
// QR scanning (Phase 3) and active entries, guest parking, violations,
// and spot overrides (Phase 6).
import 'package:flutter/material.dart';
import '../models/guard_entry.dart';
import '../models/guest_parking.dart';
import '../models/scan_entry_response.dart';
import '../models/scan_exit_response.dart';
import '../models/violation_result.dart';
import '../services/base_api_service.dart';
import '../services/guard_service.dart';

/// Manages state for all guard-role screens.
class GuardProvider extends ChangeNotifier {
  final GuardService _service = GuardService();

  // ── QR scanning (Phase 3) ─────────────────────────────────────────────────
  ScanEntryResponse? _lastEntryResult;
  ScanExitResponse?  _lastExitResult;
  bool               _isScanning  = false;
  String?            _scanError;
  bool               _isEntryMode = true;

  ScanEntryResponse? get lastEntryResult => _lastEntryResult;
  ScanExitResponse?  get lastExitResult  => _lastExitResult;
  bool               get isScanning      => _isScanning;
  String?            get scanError       => _scanError;
  bool               get isEntryMode     => _isEntryMode;
  bool               get isExitMode      => !_isEntryMode;

  // ── Active entries list (Phase 6) ─────────────────────────────────────────
  List<GuardEntry> _entries           = [];
  bool             _isLoadingEntries  = false;
  String?          _entriesError;

  List<GuardEntry> get entries         => _entries;
  bool             get isLoadingEntries => _isLoadingEntries;
  String?          get entriesError    => _entriesError;

  /// Only RESERVATION type entries.
  List<GuardEntry> get reservations =>
      _entries.where((e) => e.isReservation).toList();

  /// Only GUEST type entries.
  List<GuardEntry> get guestEntries =>
      _entries.where((e) => e.isGuest).toList();

  // ── Guest parking (Phase 6) ───────────────────────────────────────────────
  bool         _isCreatingGuest  = false;
  GuestParking? _lastCreatedGuest;
  bool         _isCompletingGuest = false;

  bool          get isCreatingGuest   => _isCreatingGuest;
  GuestParking? get lastCreatedGuest  => _lastCreatedGuest;
  bool          get isCompletingGuest => _isCompletingGuest;

  // ── Violation reporting (Phase 6) ─────────────────────────────────────────
  bool             _isReportingViolation = false;
  ViolationResult? _lastViolationResult;

  bool             get isReportingViolation => _isReportingViolation;
  ViolationResult? get lastViolationResult  => _lastViolationResult;

  // ── Spot override (Phase 6) ───────────────────────────────────────────────
  bool _isOverridingSpot = false;

  bool get isOverridingSpot => _isOverridingSpot;

  // ── General operation error (covers guest, violation, override) ───────────
  String? _operationError;

  String? get operationError => _operationError;

  // ── QR scanning methods (Phase 3) ─────────────────────────────────────────

  /// Toggles between entry and exit scan mode. Clears previous results.
  void setEntryMode(bool isEntry) {
    _isEntryMode     = isEntry;
    _lastEntryResult = null;
    _lastExitResult  = null;
    _scanError       = null;
    notifyListeners();
  }

  /// Clears last scan results — call when returning to the scanner view.
  void clearResults() {
    _lastEntryResult = null;
    _lastExitResult  = null;
    _scanError       = null;
    notifyListeners();
  }

  /// Processes a scanned QR code in the current mode (entry or exit).
  /// Never throws — sets [scanError] on network failure.
  Future<void> processScan(String qrCodeData) async {
    _isScanning      = true;
    _scanError       = null;
    _lastEntryResult = null;
    _lastExitResult  = null;
    notifyListeners();
    try {
      if (_isEntryMode) {
        _lastEntryResult = await _service.scanEntry(qrCodeData);
      } else {
        _lastExitResult = await _service.scanExit(qrCodeData);
      }
    } catch (_) {
      _scanError = 'Connection error. Please try again.';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // ── Active entries methods (Phase 6) ──────────────────────────────────────

  /// Loads combined active reservations and guest parking entries.
  /// Call when the guard active-entries screen opens.
  Future<void> loadEntries() async {
    _isLoadingEntries = true;
    _entriesError     = null;
    notifyListeners();
    try {
      _entries = await GuardService().getActiveEntries();
    } on ApiException catch (e) {
      _entriesError = e.toString();
    } catch (_) {
      _entriesError = 'Failed to load active entries';
    } finally {
      _isLoadingEntries = false;
      notifyListeners();
    }
  }

  // ── Guest parking methods (Phase 6) ───────────────────────────────────────

  /// Creates a guest parking entry for a Zone C spot.
  ///
  /// Returns the created [GuestParking] on success, null on failure.
  /// Refreshes [entries] on success. Check [operationError] on failure.
  Future<GuestParking?> createGuestParking({
    required int spotId,
    required String guestPlateNumber,
    String? purpose,
  }) async {
    _isCreatingGuest = true;
    _operationError  = null;
    notifyListeners();
    try {
      final result = await GuardService().createGuestParking(
        spotId:           spotId,
        guestPlateNumber: guestPlateNumber,
        purpose:          purpose,
      );
      _lastCreatedGuest = result;
      await loadEntries();
      return result;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return null;
    } catch (_) {
      _operationError = 'Failed to create guest parking';
      return null;
    } finally {
      _isCreatingGuest = false;
      notifyListeners();
    }
  }

  /// Marks a guest parking entry as completed (guest has left).
  ///
  /// Returns true on success and refreshes [entries].
  Future<bool> completeGuestParking(int guestParkingId) async {
    _isCompletingGuest = true;
    _operationError    = null;
    notifyListeners();
    try {
      await GuardService().completeGuestParking(guestParkingId);
      await loadEntries();
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to complete guest parking';
      return false;
    } finally {
      _isCompletingGuest = false;
      notifyListeners();
    }
  }

  // ── Violation methods (Phase 6) ───────────────────────────────────────────

  /// Reports a parking violation by plate number.
  ///
  /// [violationType]: 'NO_RESERVATION', 'WRONG_SPOT', 'UNAUTHORIZED', 'IDLING'.
  /// Returns [ViolationResult] on success, null on failure.
  /// Call [clearViolationResult] after the result dialog is dismissed.
  Future<ViolationResult?> reportViolation({
    required String plateNumber,
    required String violationType,
    String? notes,
  }) async {
    _isReportingViolation = true;
    _operationError       = null;
    _lastViolationResult  = null;
    notifyListeners();
    try {
      final result = await GuardService().reportViolation(
        plateNumber:   plateNumber,
        violationType: violationType,
        notes:         notes,
      );
      _lastViolationResult = result;
      return result;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return null;
    } catch (_) {
      _operationError = 'Failed to report violation';
      return null;
    } finally {
      _isReportingViolation = false;
      notifyListeners();
    }
  }

  // ── Spot override methods (Phase 6) ───────────────────────────────────────

  /// Overrides a spot's occupancy status with an audit reason.
  ///
  /// [newStatus]: 'AVAILABLE', 'OCCUPIED', or 'UNAVAILABLE'.
  /// [reason]: 'CAMERA_ERROR', 'LEFT_UNDETECTED', 'MAINTENANCE', 'EVENT', 'OTHER'.
  /// Returns true on success.
  Future<bool> overrideSpotStatus({
    required int    spotId,
    required String newStatus,
    required String reason,
  }) async {
    _isOverridingSpot = true;
    _operationError   = null;
    notifyListeners();
    try {
      await GuardService().overrideSpotStatus(
        spotId:    spotId,
        newStatus: newStatus,
        reason:    reason,
      );
      return true;
    } on ApiException catch (e) {
      _operationError = e.toString();
      return false;
    } catch (_) {
      _operationError = 'Failed to override spot';
      return false;
    } finally {
      _isOverridingSpot = false;
      notifyListeners();
    }
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Clears the current operation error. Call before opening a form or action sheet.
  void clearOperationError() {
    _operationError = null;
    notifyListeners();
  }

  /// Clears the last violation result. Call after the result dialog is dismissed.
  void clearViolationResult() {
    _lastViolationResult = null;
    notifyListeners();
  }

  /// Resets all Phase 6 state. Scan state is preserved intentionally.
  void reset() {
    _entries              = [];
    _isLoadingEntries     = false;
    _entriesError         = null;
    _isCreatingGuest      = false;
    _lastCreatedGuest     = null;
    _isCompletingGuest    = false;
    _isReportingViolation = false;
    _lastViolationResult  = null;
    _isOverridingSpot     = false;
    _operationError       = null;
    notifyListeners();
  }
}
