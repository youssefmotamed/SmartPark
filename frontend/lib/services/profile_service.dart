// profile_service.dart — Student profile API call: GET /profile
import '../models/user.dart';
import 'base_api_service.dart';

/// Minimal active badge info embedded in the profile response.
class ActiveBadgeInfo {
  final int    id;
  final String type;
  final String status;

  const ActiveBadgeInfo({
    required this.id,
    required this.type,
    required this.status,
  });

  factory ActiveBadgeInfo.fromJson(Map<String, dynamic> json) =>
      ActiveBadgeInfo(
        id:     json['id'],
        type:   json['type'],
        status: json['status'],
      );
}

/// Full response from GET /api/v1/profile.
class ProfileResponse {
  final int              id;
  final String           fullName;
  final String           studentId;
  final String           email;
  final String           plateNumber;
  final int              totalPoints;
  final ActiveBadgeInfo? activeBadge;
  final DateTime         createdAt;

  const ProfileResponse({
    required this.id,
    required this.fullName,
    required this.studentId,
    required this.email,
    required this.plateNumber,
    required this.totalPoints,
    this.activeBadge,
    required this.createdAt,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      ProfileResponse(
        id:          json['id'],
        fullName:    json['fullName'],
        studentId:   json['studentId']  ?? '',
        email:       json['email'],
        plateNumber: json['plateNumber'] ?? '',
        totalPoints: json['totalPoints'] ?? 0,
        activeBadge: json['activeBadge'] != null
            ? ActiveBadgeInfo.fromJson(
                json['activeBadge'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  /// Converts to our app [User] model for storage in [AuthProvider].
  User toUser() => User(
        id:          id,
        fullName:    fullName,
        email:       email,
        studentId:   studentId,
        plateNumber: plateNumber,
        role:        'STUDENT',
        isActive:    true,
        createdAt:   createdAt,
      );
}

/// Fetches the current student's full profile from the backend.
class ProfileService extends BaseApiService {
  /// Returns the logged-in student's profile.
  ///
  /// Requires a valid JWT in SharedPreferences — [BaseApiService] injects it.
  Future<ProfileResponse> getProfile() async {
    final response = await get('/profile');
    return ProfileResponse.fromJson(response['data'] as Map<String, dynamic>);
  }
}
