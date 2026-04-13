// profile_service.dart — Fetches the student profile from the SmartPark backend
import 'base_api_service.dart';

/// Active badge info embedded in the profile response.
class ActiveBadgeInfo {
  final int    id;
  final String type;
  final String status;

  const ActiveBadgeInfo({
    required this.id,
    required this.type,
    required this.status,
  });

  factory ActiveBadgeInfo.fromJson(Map<String, dynamic> json) => ActiveBadgeInfo(
        id:     json['id'] as int,
        type:   json['type'] as String,
        status: json['status'] as String,
      );

  bool get isActive => status == 'ACTIVE';
}

/// Full student profile as returned by GET /profile.
class ProfileResponse {
  final int            id;
  final String         fullName;
  final String         studentId;
  final String         email;
  final String         plateNumber;
  final int            totalPoints;
  final ActiveBadgeInfo? activeBadge;
  final DateTime       createdAt;

  const ProfileResponse({
    required this.id,
    required this.fullName,
    required this.studentId,
    required this.email,
    required this.plateNumber,
    required this.totalPoints,
    required this.activeBadge,
    required this.createdAt,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) => ProfileResponse(
        id:          json['id'] as int,
        fullName:    json['fullName'] as String,
        studentId:   json['studentId'] as String,
        email:       json['email'] as String,
        plateNumber: json['plateNumber'] as String,
        totalPoints: json['totalPoints'] as int,
        activeBadge: json['activeBadge'] != null
            ? ActiveBadgeInfo.fromJson(json['activeBadge'] as Map<String, dynamic>)
            : null,
        createdAt:   DateTime.parse(json['createdAt'] as String),
      );
}

class ProfileService extends BaseApiService {
  /// Fetches the current student's full profile including badge info.
  Future<ProfileResponse> getProfile() async {
    final response = await get('/profile');
    return ProfileResponse.fromJson(response['data'] as Map<String, dynamic>);
  }
}
