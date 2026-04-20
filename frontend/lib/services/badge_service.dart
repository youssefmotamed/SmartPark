// badge_service.dart — All badge API calls for Phase 5 (Carpool & Badges)
import '../models/badge_detail.dart';
import '../models/badge_reservation.dart';
import '../models/badge_summary.dart';
import 'base_api_service.dart';

/// Handles all calls to the /badges/* endpoints.
class BadgeService extends BaseApiService {

  /// Creates a new badge for the current student.
  ///
  /// [badgeType] must be one of: 'INDIVIDUAL', 'CARPOOL_2', 'CARPOOL_3',
  /// 'CARPOOL_4', 'CARPOOL_5'.
  /// [semesterNumber] is 1 or 2. [semesterYear] is e.g. 2026.
  Future<BadgeDetail> createBadge({
    required String badgeType,
    required int    semesterNumber,
    required int    semesterYear,
  }) async {
    final response = await post('/badges', body: {
      'badgeType':      badgeType,
      'semesterNumber': semesterNumber,
      'semesterYear':   semesterYear,
    });
    return BadgeDetail.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Invites a student to join a carpool badge by their university student ID.
  ///
  /// Only the badge creator (canInvite == true) may call this.
  /// Returns the updated [BadgeDetail] with the new pending member slot.
  Future<BadgeDetail> inviteMember({
    required int    badgeId,
    required String studentId,
  }) async {
    final response = await post('/badges/$badgeId/invite', body: {
      'studentId': studentId,
    });
    return BadgeDetail.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Accepts a pending carpool invitation for the current student.
  ///
  /// The invitation must already exist (created via [inviteMember]).
  /// Returns the updated [BadgeDetail] with the member status set to ACCEPTED.
  Future<BadgeDetail> acceptInvitation(int badgeId) async {
    final response = await post('/badges/$badgeId/accept');
    return BadgeDetail.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Adds an extra car to an accepted member's carpool slot.
  ///
  /// [forUserId] is the DB user ID (int) of the accepted member who owns the slot.
  /// [carModel] is optional and may be omitted.
  Future<BadgeDetail> addCar({
    required int    badgeId,
    required String plateNumber,
    required int    forUserId,
    String?         carModel,
  }) async {
    final body = <String, dynamic>{
      'plateNumber': plateNumber,
      'forUserId':   forUserId,
    };
    if (carModel != null) body['carModel'] = carModel;
    final response = await post('/badges/$badgeId/add-car', body: body);
    return BadgeDetail.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Returns full badge detail including members, cars, and slot info.
  Future<BadgeDetail> getBadgeDetail(int badgeId) async {
    final response = await get('/badges/$badgeId');
    return BadgeDetail.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Returns the current active reservation for a badge.
  ///
  /// Throws [ApiException] with status 404 if no active reservation exists.
  Future<BadgeReservation> getBadgeReservation(int badgeId) async {
    final response = await get('/badges/$badgeId/reservation');
    return BadgeReservation.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Returns the list of all badges belonging to the current student.
  ///
  /// Maps to GET /profile/badges. Returns lightweight [BadgeSummary] objects.
  Future<List<BadgeSummary>> getProfileBadges() async {
    final response = await get('/profile/badges');
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => BadgeSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
