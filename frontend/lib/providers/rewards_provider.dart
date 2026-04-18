// rewards_provider.dart — Manages rewards catalogue and redemption flow for SmartPark
import 'package:flutter/foundation.dart';
import '../models/reward.dart';
import '../services/rewards_service.dart';
import '../services/base_api_service.dart';

/// Manages state for the Phase 4 Rewards screen (S12) and redemption flow.
///
/// Handles:
/// - Rewards catalogue list with server-computed [Reward.canAfford] flags
/// - Full redemption flow with loading/error state
/// - Advance reservation unlock flag for navigating to S14
class RewardsProvider extends ChangeNotifier {
  final RewardsService _service = RewardsService();

  // ── Rewards list ──────────────────────────────────────────────────────────
  List<Reward> _rewards   = [];
  bool         _isLoading = false;
  String?      _error;

  // ── Redemption ────────────────────────────────────────────────────────────
  bool                    _isRedeeming               = false;
  String?                 _redemptionError;
  Map<String, dynamic>?   _lastRedemptionResult;
  bool                    _advanceReservationUnlocked = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Reward>           get rewards                    => _rewards;
  bool                   get isLoading                  => _isLoading;
  String?                get error                      => _error;
  bool                   get isRedeeming                => _isRedeeming;
  String?                get redemptionError            => _redemptionError;
  Map<String, dynamic>?  get lastRedemptionResult       => _lastRedemptionResult;
  bool                   get advanceReservationUnlocked => _advanceReservationUnlocked;

  // ── Rewards list ──────────────────────────────────────────────────────────

  /// Loads all available rewards from the catalogue. Call when S12 opens.
  ///
  /// The [Reward.canAfford] flag on each item is computed server-side against
  /// the student's current badge balance.
  Future<void> loadRewards() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      _rewards = await _service.getRewards();
      _error   = null;
    } on ApiException catch (e) {
      _error = e.toString();
    } catch (_) {
      _error = 'Failed to load rewards.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Redemption ────────────────────────────────────────────────────────────

  /// Redeems the reward with [rewardId]. Returns true on success, false on failure.
  ///
  /// On success:
  /// - Stores the full API result in [lastRedemptionResult]
  /// - Sets [advanceReservationUnlocked] if the reward type is ADVANCE_RESERVATION
  /// - Reloads the rewards list so [Reward.canAfford] flags reflect the new balance
  ///
  /// On failure:
  /// - Sets [redemptionError] with the server error message
  Future<bool> redeemReward(int rewardId, {VoidCallback? onSuccess}) async {
    _isRedeeming      = true;
    _redemptionError  = null;
    _lastRedemptionResult = null;
    notifyListeners();

    try {
      final result = await _service.redeemReward(rewardId);
      _lastRedemptionResult = result;

      if (result['rewardType'] == 'ADVANCE_RESERVATION') {
        _advanceReservationUnlocked = true;
      }

      await loadRewards();
      onSuccess?.call();

      return true;
    } on ApiException catch (e) {
      _redemptionError = e.toString();
      return false;
    } catch (_) {
      _redemptionError = 'Redemption failed. Please try again.';
      return false;
    } finally {
      _isRedeeming = false;
      notifyListeners();
    }
  }

  // ── Unlock flag ───────────────────────────────────────────────────────────

  /// Clears the advance reservation unlock flag.
  /// Call after navigating to the advance reservation screen (S14).
  void clearAdvanceReservationUnlock() {
    _advanceReservationUnlocked = false;
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  /// Resets all state. Call on logout.
  void reset() {
    _rewards                    = [];
    _isLoading                  = false;
    _isRedeeming                = false;
    _error                      = null;
    _redemptionError            = null;
    _lastRedemptionResult       = null;
    _advanceReservationUnlocked = false;
    notifyListeners();
  }
}
