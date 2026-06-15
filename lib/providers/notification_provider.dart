// lib/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _nextCursor;
  IO.Socket? _socket;

  NotificationProvider(this._service);

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _nextCursor != null;

  /// Initialize notifications and start socket
  Future<void> init(String userId) async {
    await fetchNotifications(forceRefresh: true);
    _initSocket(userId);
  }

  /// Initial load or refresh
  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _nextCursor == null) return;

    _isLoading = true;
    if (forceRefresh) {
      _notifications = [];
      _nextCursor = null;
    }
    notifyListeners();

    try {
      final result = await _service.fetchNotifications(cursor: _nextCursor);
      _notifications.addAll(result['notifications']);
      _nextCursor = result['next'];
      _unreadCount = result['unreadCount'];
    } catch (e) {
      if (kDebugMode) print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark as read
  Future<void> markAsRead(String id) async {
    try {
      final updated = await _service.markAsRead(id);

      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        if (!_notifications[index].isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }
        _notifications[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print('Error marking notification as read: $e');
    }
  }

  /// Socket.IO Integration
  void _initSocket(String userId) {
    if (_socket != null) return;

    // TODO: Move base URL and slugs to a config file
    const socketUrl =
        'https://qkicsbackend.matchb.online'; // Verify this URL for Socket.IO
        

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({
            'clientId': 'qkics', // Replace with actual client slug
            'appId': 'main', // Replace with actual app slug
            'userId': userId,
          })
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      if (kDebugMode) print('Socket connected');
    });
    _socket!.onDisconnect((_) {
      if (kDebugMode) print('Socket disconnected');
    });

    _socket!.on('notification', (data) {
      if (kDebugMode) print('New real-time notification: $data');
      _onSocketNotification(data);
    });

    _socket!.connect();
  }

  void _onSocketNotification(dynamic data) {
    if (data is Map<String, dynamic>) {
      final notification = NotificationModel.fromJson(data);
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    }
  }

  void disposeSession() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _notifications = [];
    _unreadCount = 0;
    _nextCursor = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeSession();
    super.dispose();
  }
}
