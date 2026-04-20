// badge_car.dart — A registered car inside a carpool badge
import 'package:flutter/foundation.dart';

/// A car registered to a carpool slot within a [BadgeDetail].
@immutable
class BadgeCar {
  /// The licence plate number.
  final String plate;

  /// Display name of the member who owns this car slot.
  final String ownerName;

  const BadgeCar({
    required this.plate,
    required this.ownerName,
  });

  factory BadgeCar.fromJson(Map<String, dynamic> json) {
    return BadgeCar(
      plate:     json['plate'] as String,
      ownerName: (json['ownerName'] ?? json['owner'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'plate':     plate,
    'ownerName': ownerName,
  };
}
