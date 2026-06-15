// lib/services/notification_service.dart
import 'package:dio/dio.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  /// Fetch paginated notifications
 Future<Map<String, dynamic>> fetchNotifications({String? cursor}) async {
  final response = await _dio.get(
    '/api/v1/notifications/',
    queryParameters: {
      'channel': 'IN_APP',
      'limit': 20,
      if (cursor != null) 'cursor': cursor,
    },
  );

  if (response.statusCode == 200) {
    final body = response.data;

    // 👇 CORRECT JSON PATH
    final data = body['data'] ?? {};

    final List rawList = data['notifications'] ?? [];

    final notifications = rawList
        .map((json) => NotificationModel.fromJson(json))
        .toList();

    print("Parsed notifications count: ${notifications.length}");

    return {
      'notifications': notifications,
      'next': data['next'], // may be null
      'unreadCount': data['unreadCount'] ?? 0,
    };
  }

  throw DioException(
    requestOptions: response.requestOptions,
    response: response,
    type: DioExceptionType.badResponse,
  );
}

  /// Mark a notification as read
  Future<NotificationModel> markAsRead(String id) async {
    final response = await _dio.post('/api/v1/notifications/$id/read/');

    if (response.statusCode == 200) {
      return NotificationModel.fromJson(response.data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }

  /// Register FCM push token
  Future<void> registerPushToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    await _dio.post(
      '/api/v1/notifications/push-token/register/',
      data: {
        'token': token,
        'platform': platform,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
  }

  /// Unregister FCM push token
  Future<void> unregisterPushToken(String token) async {
    await _dio.post(
      '/api/v1/notifications/push-token/unregister/',
      data: {'token': token},
    );
  }
}
