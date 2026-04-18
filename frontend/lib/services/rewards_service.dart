// rewards_service.dart — API service for rewards catalogue and redemption endpoints
import '../models/redemption_record.dart';
import '../models/reward.dart';
import 'base_api_service.dart';

/// Handles all calls to the /rewards/* endpoints.
class RewardsService extends BaseApiService {

  /// Fetches all available rewards from the catalogue.
  ///
  /// The `canAfford` field on each [Reward] is computed server-side against
  /// the current student's active badge balance.
  /// Maps to GET /rewards → response['data'] (list).
  Future<List<Reward>> getRewards() async {
    final response = await get('/rewards');
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => Reward.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Redeems the reward with [rewardId] for the current student.
  ///
  /// Returns a map containing: redemptionId, rewardName, rewardType,
  /// pointsDeducted, remainingBalance, redeemedAt.
  /// Maps to POST /rewards/{rewardId}/redeem (no request body).
  Future<Map<String, dynamic>> redeemReward(int rewardId) async {
    final response = await post('/rewards/$rewardId/redeem');
    return response['data'] as Map<String, dynamic>;
  }

  /// Fetches the full redemption history for the current student.
  /// Maps to GET /rewards/redemptions → response['data'] (list).
  Future<List<RedemptionRecord>> getRedemptions() async {
    final response = await get('/rewards/redemptions');
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => RedemptionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
