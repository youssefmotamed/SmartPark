// spots_service.dart — Fetches zones and spots from the SmartPark backend
import '../models/spot.dart';
import '../models/zone.dart';
import 'base_api_service.dart';

class SpotsService extends BaseApiService {

  /// Fetches all spots. Optional [zoneCode] filter.
  Future<List<Spot>> getSpots({String? zoneCode}) async {
    final path = zoneCode != null ? '/spots?zoneCode=$zoneCode' : '/spots';
    final response = await get(path);
    final List<dynamic> data = response['data'] as List<dynamic>;
    return data.map((json) => Spot.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Fetches all zones.
  Future<List<Zone>> getZones() async {
    final response = await get('/zones');
    final List<dynamic> data = response['data'] as List<dynamic>;
    return data.map((json) => Zone.fromJson(json as Map<String, dynamic>)).toList();
  }
}
