// points_service.dart — API service for points balance, history, and summary endpoints
import '../models/points_balance.dart';
import '../models/points_summary.dart';
import '../models/points_transaction.dart';
import 'base_api_service.dart';

/// Handles all calls to the /points/* endpoints.
class PointsService extends BaseApiService {

  /// Fetches the current points balance and badge multiplier.
  ///
  /// Pass [badgeId] to retrieve balance for a specific badge; omit to use
  /// whatever the backend considers the active badge.
  /// Maps to GET /points/balance → response['data'].
  Future<PointsBalance> getBalance({int? badgeId}) async {
    final path = badgeId != null
        ? '/points/balance?badgeId=$badgeId'
        : '/points/balance';
    final response = await get(path);
    return PointsBalance.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Fetches aggregate summary statistics (total earned, spent, expiring soon).
  ///
  /// Pass [badgeId] to scope the summary to a specific badge.
  /// Maps to GET /points/summary → response['data'].
  Future<PointsSummary> getSummary({int? badgeId}) async {
    final path = badgeId != null
        ? '/points/summary?badgeId=$badgeId'
        : '/points/summary';
    final response = await get(path);
    return PointsSummary.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Fetches a paginated page of points transaction history.
  ///
  /// [type] filters by transaction type: 'EARNED', 'SPENT', 'EXPIRED', or null for all.
  /// [badgeId] scopes the history to a specific badge.
  /// [page] is zero-indexed. [size] defaults to 20.
  ///
  /// Returns the raw `data` map so the provider can read both `content` and
  /// pagination fields (page, size, totalElements, totalPages, etc.).
  Future<Map<String, dynamic>> getHistory({
    String? type,
    int?    badgeId,
    int     page = 0,
    int     size = 20,
  }) async {
    final buffer = StringBuffer('/points/history?page=$page&size=$size');
    if (type != null)    buffer.write('&type=$type');
    if (badgeId != null) buffer.write('&badgeId=$badgeId');
    final response = await get(buffer.toString());
    return response['data'] as Map<String, dynamic>;
  }

  /// Parses a raw history page map into a list of [PointsTransaction] objects.
  /// Call this on the result of [getHistory] to get typed models.
  List<PointsTransaction> parseTransactions(Map<String, dynamic> data) {
    final content = data['content'] as List<dynamic>;
    return content
        .map((e) => PointsTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
