// spots_provider.dart — Manages parking spot state and 30-second polling
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/spot.dart';
import '../models/zone.dart';
import '../services/spots_service.dart';
import '../services/base_api_service.dart';
import '../config/constants.dart';

class SpotsProvider extends ChangeNotifier {
  final SpotsService _service = SpotsService();

  List<Spot> _spots     = [];
  List<Zone> _zones     = [];
  bool       _isLoading = false;
  String?    _error;
  Spot?      _selectedSpot;
  bool       _isTooFar  = false;
  bool       _geoChecked = false;
  bool       _isPolling = false;
  Timer?     _pollTimer;

  // Refresh pulse — incremented each time fetchSpots completes.
  int        _refreshTick = 0;

  List<Spot> get spots        => _spots;
  List<Zone> get zones        => _zones;
  bool       get isLoading    => _isLoading;
  String?    get error        => _error;
  Spot?      get selectedSpot => _selectedSpot;
  bool       get isTooFar     => _isTooFar;
  bool       get geoChecked   => _geoChecked;
  int        get refreshTick  => _refreshTick;

  /// Spots belonging to a given zone code, sorted by label.
  List<Spot> spotsForZone(String zoneCode) {
    final list = _spots.where((s) => s.zoneCode == zoneCode).toList();
    list.sort((a, b) => a.spotLabel.compareTo(b.spotLabel));
    return list;
  }

  /// Loads spots (and zones on first call) from the backend.
  Future<void> fetchSpots() async {
    _error = null;
    if (_spots.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final fetchZones = _zones.isEmpty;
      if (fetchZones) {
        final results = await Future.wait([
          _service.getSpots(),
          _service.getZones(),
        ]);
        _spots = results[0] as List<Spot>;
        _zones = results[1] as List<Zone>;
      } else {
        _spots = await _service.getSpots();
      }
      _refreshTick++;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load parking data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts 30-second polling. Safe to call multiple times.
  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    fetchSpots();
    _pollTimer = Timer.periodic(
      Duration(seconds: AppConstants.pollingIntervalSeconds),
      (_) => fetchSpots(),
    );
  }

  /// Stops polling. Call from the screen's dispose().
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  void selectSpot(Spot spot) {
    _selectedSpot = spot;
    notifyListeners();
  }

  void clearSelectedSpot() {
    _selectedSpot = null;
    notifyListeners();
  }

  void setGeoResult({required bool isTooFar}) {
    _isTooFar   = isTooFar;
    _geoChecked = true;
    notifyListeners();
  }

  /// Dev-only: skip geolocation check.
  void bypassGeo() {
    _isTooFar   = false;
    _geoChecked = true;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
