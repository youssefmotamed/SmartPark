// reservation_service.dart — Handles all reservation API calls for SmartPark
import '../models/reservation_response.dart';
import '../models/reservation_history_page.dart';
import '../models/create_reservation_request.dart';
import 'base_api_service.dart';

class ReservationService extends BaseApiService {

  /// Creates a new reservation.
  /// Throws [ApiException] on 422 (business rule violation) or 404 (spot/badge not found).
  Future<ReservationResponse> createReservation(CreateReservationRequest request) async {
    final response = await post('/reservations', body: request.toJson());
    return ReservationResponse.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Gets the current active reservation.
  /// Returns null if none exists (404 response).
  Future<ReservationResponse?> getActiveReservation() async {
    try {
      final response = await get('/reservations/active');
      return ReservationResponse.fromJson(response['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Gets paginated reservation history.
  /// Optional [status] filter: COMPLETED, EXPIRED, CANCELLED.
  Future<ReservationHistoryPage> getHistory({
    int page = 0,
    int size = 20,
    String? status,
  }) async {
    String path = '/reservations/history?page=$page&size=$size';
    if (status != null) path += '&status=$status';
    final response = await get(path);
    return ReservationHistoryPage.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Cancels an active reservation.
  /// Throws [ApiException] on 422 (not cancellable) or 403 (not owner).
  Future<void> cancelReservation(int reservationId) async {
    await delete('/reservations/$reservationId');
  }

  /// Gets the QR code string for a reservation.
  /// The data field is a plain String, not an object.
  Future<String> getQrCode(int reservationId) async {
    final response = await get('/reservations/$reservationId/qr');
    return response['data'] as String;
  }
}
