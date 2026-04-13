// guard_provider.dart — Manages guard scanning state for SmartPark
import 'package:flutter/material.dart';
import '../models/scan_entry_response.dart';
import '../models/scan_exit_response.dart';
import '../services/guard_service.dart';

class GuardProvider extends ChangeNotifier {
  final GuardService _service = GuardService();

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
}
