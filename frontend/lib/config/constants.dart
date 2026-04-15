// constants.dart — App-wide constant values for SmartPark (campus coords, timers, limits)
import 'package:flutter/foundation.dart';

/// Centralised constants — never use magic numbers anywhere else in the app.
@immutable
class AppConstants {
  const AppConstants._();

  /// AAST Abu Qir campus latitude.
  static const double campusLatitude = 31.2001;

  /// AAST Abu Qir campus longitude.
  static const double campusLongitude = 29.9187;

  /// Maximum allowed distance from campus (km) to create a reservation.
  static const double maxDistanceKm = 5.0;

  /// Minutes before entry scan that a reservation expires.
  static const int reservationTimerMinutes = 15;

  /// Interval (seconds) at which the app polls the backend for updates.
  static const int pollingIntervalSeconds = 10;

  /// Number of consecutive empty camera readings before a spot is considered vacated.
  static const int departureBufferSeconds = 60;

  /// Maximum number of members in a carpool badge.
  static const int maxCarpoolSize = 5;

  /// Minimum number of members in a carpool badge.
  static const int minCarpoolSize = 2;
}
