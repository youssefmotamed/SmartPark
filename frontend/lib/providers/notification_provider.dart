// notification_provider.dart — Manages notification state and polling for SmartPark
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/base_api_service.dart';
import '../config/constants.dart';

/// Manages notification state across the app.
///
/// - Polls unread count every 30 s for the bell badge in the shell top bars.
/// - Loads the full notification list on demand when the screen opens.
/// - Marks individual or all notifications as read with optimistic updates.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  // ── Bell badge state (polled) ─────────────────────────────────────────────
  int    _unreadCount = 0;
  Timer? _pollTimer;
  bool   _isPolling   = false;

  // ── Full list state (loaded on screen open) ───────────────────────────────
  List<AppNotification> _notifications = [];
  bool                  _isLoadingList = false;
  String?               _listError;
  int                   _currentPage   = 0;
  bool                  _hasMorePages  = false;

  // ── Mark-all state ────────────────────────────────────────────────────────
  bool _isMarkingAll = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  int                   get unreadCount   => _unreadCount;
  List<AppNotification> get notifications => _notifications;
  bool                  get isLoadingList => _isLoadingList;
  String?               get listError     => _listError;
  bool                  get hasMorePages  => _hasMorePages;
  bool                  get isMarkingAll  => _isMarkingAll;
  bool                  get hasUnread     => _unreadCount > 0;

  // ── Polling ───────────────────────────────────────────────────────────────

  /// Starts polling the unread count every [AppConstants.pollingIntervalSeconds].
  /// Safe to call multiple times — ignores subsequent calls while already polling.
  /// Call from [StudentShell] and [GuardShell] initState.
  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _fetchUnreadCount();
    _pollTimer = Timer.periodic(
      Duration(seconds: AppConstants.pollingIntervalSeconds),
      (_) => _fetchUnreadCount(),
    );
  }

  /// Stops polling. Call from shell dispose().
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await _service.getUnreadCount();
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Silently fail — bell shows stale count rather than breaking the UI
    }
  }

  // ── Full notification list ────────────────────────────────────────────────

  /// Resets and fetches page 0 of the notification list.
  /// Call when the notifications screen first opens.
  Future<void> fetchNotifications() async {
    _currentPage   = 0;
    _notifications = [];
    _isLoadingList = true;
    _listError     = null;
    notifyListeners();

    try {
      final page     = await _service.getNotifications(page: 0);
      _notifications = page.content;
      _hasMorePages  = page.hasMore;
      _currentPage   = 0;
    } on ApiException catch (e) {
      _listError = e.message;
    } catch (_) {
      _listError = 'Failed to load notifications.';
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  /// Loads the next page and appends it to [notifications].
  Future<void> loadMore() async {
    if (!_hasMorePages || _isLoadingList) return;
    _isLoadingList = true;
    notifyListeners();
    try {
      final page = await _service.getNotifications(page: _currentPage + 1);
      _notifications.addAll(page.content);
      _hasMorePages = page.hasMore;
      _currentPage++;
    } catch (_) {
      // Silently fail — existing items remain visible
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  // ── Mark as read ──────────────────────────────────────────────────────────

  /// Marks a single notification as read.
  /// Updates the UI immediately (optimistic), then syncs with the backend.
  Future<void> markAsRead(int notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && _notifications[index].isUnread) {
      _notifications[index] = _notifications[index].copyWithRead();
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
    try {
      await _service.markAsRead(notificationId);
    } catch (_) {
      // Silently fail — optimistic update stays
    }
  }

  /// Marks all notifications as read.
  /// Updates the UI immediately, then syncs with the backend.
  Future<void> markAllAsRead() async {
    _isMarkingAll  = true;
    _notifications = _notifications.map((n) => n.read ? n : n.copyWithRead()).toList();
    _unreadCount   = 0;
    notifyListeners();

    try {
      await _service.markAllAsRead();
    } catch (_) {
      // Silently fail
    } finally {
      _isMarkingAll = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
