// points_provider.dart — Manages points balance, summary, and paginated history for SmartPark
import 'package:flutter/material.dart';
import '../models/points_balance.dart';
import '../models/points_summary.dart';
import '../models/points_transaction.dart';
import '../services/points_service.dart';
import '../services/base_api_service.dart';

/// Manages state for the Phase 4 Points screen (S10).
///
/// Handles:
/// - Points balance and summary (loaded in parallel on screen open)
/// - Paginated transaction history with EARNED / SPENT / EXPIRED filter
/// - Infinite scroll via [loadMoreHistory]
class PointsProvider extends ChangeNotifier {
  final PointsService _service = PointsService();

  static const int _pageSize = 20;

  // ── Balance & summary ─────────────────────────────────────────────────────
  PointsBalance?  _balance;
  PointsSummary?  _summary;
  bool            _isLoadingBalance  = false;
  bool            _isLoadingSummary  = false;

  // ── Active badge context ──────────────────────────────────────────────────
  int? _badgeId; // null = backend uses whatever it considers active

  // ── History ───────────────────────────────────────────────────────────────
  List<PointsTransaction> _transactions  = [];
  bool                    _isLoadingHistory = false;
  bool                    _isLoadingMore    = false;
  int                     _currentPage      = 0;
  bool                    _hasMore          = false;
  String?                 _selectedFilter;   // null = All

  // ── Error ─────────────────────────────────────────────────────────────────
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  PointsBalance?          get balance           => _balance;
  PointsSummary?          get summary           => _summary;
  bool                    get isLoadingBalance  => _isLoadingBalance;
  bool                    get isLoadingSummary  => _isLoadingSummary;
  List<PointsTransaction> get transactions      => _transactions;
  bool                    get isLoadingHistory  => _isLoadingHistory;
  bool                    get isLoadingMore     => _isLoadingMore;
  bool                    get hasMore           => _hasMore;
  String?                 get selectedFilter    => _selectedFilter;
  String?                 get error             => _error;

  // ── Balance + summary ─────────────────────────────────────────────────────

  /// Loads balance and summary in parallel for [badgeId].
  ///
  /// Pass [badgeId] to scope data to the user's selected default badge.
  /// The badge ID is stored so [loadHistory] and pagination use the same badge.
  Future<void> loadBalanceAndSummary({int? badgeId}) async {
    _badgeId          = badgeId;
    _isLoadingBalance = true;
    _isLoadingSummary = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getBalance(badgeId: badgeId),
        _service.getSummary(badgeId: badgeId),
      ]);
      _balance = results[0] as PointsBalance;
      _summary = results[1] as PointsSummary;
      _error   = null;
    } on ApiException catch (e) {
      _error = e.toString();
    } catch (_) {
      _error = 'Failed to load points data.';
    } finally {
      _isLoadingBalance = false;
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  /// Loads page 0 of transaction history for [badgeId], resetting any previous data.
  ///
  /// If [badgeId] is omitted, uses the stored badge ID from the last
  /// [loadBalanceAndSummary] call. Respects the current [selectedFilter].
  Future<void> loadHistory({int? badgeId}) async {
    if (badgeId != null) _badgeId = badgeId;
    _isLoadingHistory = true;
    _currentPage      = 0;
    _transactions     = [];
    _error            = null;
    notifyListeners();

    try {
      final data  = await _service.getHistory(
        type:    _selectedFilter,
        badgeId: _badgeId,
        page:    0,
      );
      final items = _service.parseTransactions(data);
      _transactions = items;
      _currentPage  = (data['number'] as num?)?.toInt() ?? 0;
      final total   = (data['totalElements'] as num?)?.toInt() ?? 0;
      _hasMore      = (_currentPage + 1) * _pageSize < total;
    } on ApiException catch (e) {
      _error = e.toString();
    } catch (_) {
      _error = 'Failed to load transaction history.';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Loads the next page and appends to [transactions]. No-op if already
  /// loading or no more pages exist.
  Future<void> loadMoreHistory() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final data  = await _service.getHistory(
        type:    _selectedFilter,
        badgeId: _badgeId,
        page:    _currentPage + 1,
      );
      final items = _service.parseTransactions(data);
      _transactions.addAll(items);
      _currentPage = (data['number'] as num?)?.toInt() ?? (_currentPage + 1);
      final total  = (data['totalElements'] as num?)?.toInt() ?? 0;
      _hasMore     = (_currentPage + 1) * _pageSize < total;
    } on ApiException catch (e) {
      _error = e.toString();
    } catch (_) {
      // Silently fail — existing items remain visible
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Sets the active filter and reloads history from page 0.
  ///
  /// Pass null to show all transaction types.
  Future<void> setFilter(String? filter) async {
    _selectedFilter = filter;
    await loadHistory();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  /// Resets all state. Call on logout.
  void reset() {
    _badgeId          = null;
    _balance          = null;
    _summary          = null;
    _transactions     = [];
    _isLoadingBalance = false;
    _isLoadingSummary = false;
    _isLoadingHistory = false;
    _isLoadingMore    = false;
    _currentPage      = 0;
    _hasMore          = false;
    _selectedFilter   = null;
    _error            = null;
    notifyListeners();
  }
}
