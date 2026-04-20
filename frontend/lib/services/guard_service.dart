// guard_service.dart — Handles all guard API calls for SmartPark
import '../models/guest_parking.dart';
import '../models/guard_entry.dart';
import '../models/scan_entry_response.dart';
import '../models/scan_exit_response.dart';
import '../models/violation_result.dart';
import 'base_api_service.dart';

/// API service for all guard-role endpoints.
class GuardService extends BaseApiService {

  /// Scans a QR code for gate entry.
  ///
  /// Always returns HTTP 200 — check [ScanEntryResponse.isValid] for the result.
  /// Only throws on network errors, never on scan validation failures.
  Future<ScanEntryResponse> scanEntry(String qrCodeData) async {
    final response = await post('/gate/scan-entry', body: {'qrCodeData': qrCodeData});
    return ScanEntryResponse.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Scans a QR code for gate exit.
  ///
  /// Always returns HTTP 200 — check [ScanExitResponse.isSuccess] for the result.
  /// Only throws on network errors, never on scan validation failures.
  Future<ScanExitResponse> scanExit(String qrCodeData) async {
    final response = await post('/gate/scan-exit', body: {'qrCodeData': qrCodeData});
    return ScanExitResponse.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Gets the combined list of active student reservations and guest parking
  /// entries currently on campus. Maps to GET /guard/reservations.
  Future<List<GuardEntry>> getActiveEntries() async {
    final response = await get('/guard/reservations');
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => GuardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Creates a guest parking entry for a Zone C spot.
  ///
  /// [purpose] is optional free-text (e.g. 'Delivery', 'Visitor').
  /// Maps to POST /guard/guest-parking.
  Future<GuestParking> createGuestParking({
    required int spotId,
    required String guestPlateNumber,
    String? purpose,
  }) async {
    final body = <String, dynamic>{
      'spotId': spotId,
      'guestPlateNumber': guestPlateNumber,
    };
    if (purpose != null && purpose.isNotEmpty) body['purpose'] = purpose;
    final response = await post('/guard/guest-parking', body: body);
    return GuestParking.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Marks an active guest parking entry as completed (guest has left).
  /// Maps to PATCH /guard/guest-parking/{id}/complete.
  Future<GuestParking> completeGuestParking(int guestParkingId) async {
    final response =
        await patch('/guard/guest-parking/$guestParkingId/complete');
    return GuestParking.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Reports a parking violation by plate number.
  ///
  /// [violationType]: 'NO_RESERVATION', 'WRONG_SPOT', 'UNAUTHORIZED', 'IDLING'.
  /// [notes] is optional. Maps to POST /guard/violations.
  Future<ViolationResult> reportViolation({
    required String plateNumber,
    required String violationType,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'plateNumber': plateNumber,
      'violationType': violationType,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    final response = await post('/guard/violations', body: body);
    return ViolationResult.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Overrides a spot's occupancy status with an audit reason.
  ///
  /// [newStatus]: 'AVAILABLE', 'OCCUPIED', or 'UNAVAILABLE'.
  /// [reason]: 'CAMERA_ERROR', 'LEFT_UNDETECTED', 'MAINTENANCE', 'EVENT', 'OTHER'.
  /// Maps to PATCH /guard/spots/{spotId}/override.
  Future<void> overrideSpotStatus({
    required int spotId,
    required String newStatus,
    required String reason,
  }) async {
    await patch('/guard/spots/$spotId/override', body: {
      'newStatus': newStatus,
      'reason': reason,
    });
  }
}
