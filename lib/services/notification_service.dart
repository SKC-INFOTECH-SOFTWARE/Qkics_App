// lib/services/notification_service.dart
import 'package:dio/dio.dart';
import '../models/notification_model.dart';

/// REST-only client for the standalone notification microservice.
/// Real-time delivery is intentionally not used here; the inbox is
/// refreshed via polling (screen open, pull-to-refresh, or a timer).
class NotificationService {
  static const String _baseUrl = "https://notification.mesmi.co.in";
  static const String _apiKey = "ns_skc_d81ae6b063768ddb8b4d553c922d71fe6f68c6bb";

  final Dio _dio;

  NotificationService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            "x-api-key": _apiKey,
            "Content-Type": "application/json",
          },
        ),
      );

  /// Fetch a page of notifications for [userId].
  Future<Map<String, dynamic>> fetchNotifications({
    required String userId,
    int limit = 20,
    int offset = 0,
    String? channel,
    String? status,
  }) async {
    final response = await _dio.get(
      '/api/notifications',
      queryParameters: {
        'userId': userId,
        'limit': limit,
        'offset': offset,
        if (channel != null) 'channel': channel,
        if (status != null) 'status': status,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? {};
      final List rawList = data['notifications'] ?? [];

      final notifications = rawList
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      return {
        'notifications': notifications,
        'total': data['total'] ?? notifications.length,
        'unreadCount': data['unreadCount'] ?? 0,
      };
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String id) async {
    final response = await _dio.patch('/api/notifications/$id/read');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  }

  /// Register an FCM push token for [userId] (call after login).
  Future<void> registerPushToken({
    required String userId,
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    await _dio.post(
      '/api/push-tokens/register',
      data: {
        'userId': userId,
        'token': token,
        'platform': platform,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
  }

  /// Unregister an FCM push token (call on logout).
  Future<void> unregisterPushToken(String token) async {
    await _dio.post('/api/push-tokens/unregister', data: {'token': token});
  }
}
