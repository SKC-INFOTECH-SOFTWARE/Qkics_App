// lib/providers/notification_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service;

  static const int _pageSize = 20;
  static const Duration _pollInterval = Duration(seconds: 45);

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  int _total = 0;
  bool _isLoading = false;
  String? _userId;
  Timer? _pollTimer;

  NotificationProvider(this._service);

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _notifications.length < _total;

  /// Initialize notifications for [userId] and start polling for updates.
  Future<void> init(String userId) async {
    _userId = userId;
    await fetchNotifications(forceRefresh: true);
    _startPolling();
  }

  /// Initial load, pagination, or refresh.
  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    final userId = _userId;
    if (userId == null) return;
    if (_isLoading) return;
    if (!forceRefresh && _notifications.length >= _total && _total != 0) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final offset = forceRefresh ? 0 : _notifications.length;
      final result = await _service.fetchNotifications(
        userId: userId,
        limit: _pageSize,
        offset: offset,
        channel: 'IN_APP',
      );

      final fetched = result['notifications'] as List<NotificationModel>;
      _notifications = forceRefresh ? fetched : [..._notifications, ...fetched];
      _total = result['total'];
      _unreadCount = result['unreadCount'];
    } catch (e) {
      if (kDebugMode) print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark as read (optimistic local update; the API has no read-state body).
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    try {
      await _service.markAsRead(id);
      _notifications[index] = _notifications[index].copyWith(
        readAt: DateTime.now(),
      );
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      fetchNotifications(forceRefresh: true);
    });
  }

  void disposeSession() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _userId = null;
    _notifications = [];
    _unreadCount = 0;
    _total = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeSession();
    super.dispose();
  }
}
