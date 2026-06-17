// lib/services/push_notification_service.dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification_service.dart';

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  late final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  NotificationService? _apiService;

  void setApiService(NotificationService apiService) {
    _apiService = apiService;
  }

  Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) print('Firebase not initialized. Skipping FCM setup.');
      return;
    }
    _fcm = FirebaseMessaging.instance;
    // Request permissions (especially for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
    }

    // Initialize local notifications for foreground display
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    // Create high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages (when user taps)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    // Handle tap on local notification (foreground)
    if (kDebugMode) print('Local notification tapped: ${response.payload}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle tap on system notification (background)
    if (kDebugMode) print('System notification tapped: ${message.data}');
    // Navigation logic will be handled via a GlobalKey or similar in the UI layer
  }

  Future<void> registerToken({required String userId}) async {
    if (_apiService == null) return;

    try {
      String? token;
      if (Platform.isIOS) {
        token = await _fcm.getAPNSToken();
      }

      // Even on iOS, Firebase needs the FCM token for delivery
      token = await _fcm.getToken();

      if (token != null) {
        await _apiService!.registerPushToken(
          userId: userId,
          token: token,
          platform: Platform.isAndroid ? 'android' : 'ios',
          deviceId: null, // Optional
        );
        if (kDebugMode) print('FCM Token registered: $token');
      }
    } catch (e) {
      if (kDebugMode) print('Error registering FCM token: $e');
    }
  }

  Future<void> unregisterToken() async {
    if (_apiService == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _apiService!.unregisterPushToken(token);
        if (kDebugMode) print('FCM Token unregistered');
      }
    } catch (e) {
      if (kDebugMode) print('Error unregistering FCM token: $e');
    }
  }
}
