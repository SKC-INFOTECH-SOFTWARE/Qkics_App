// lib/subscriptions/services/subscription_service.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import '../models/subscription_plan.dart';
import '../models/active_subscription.dart';

class SubscriptionService {
  final Dio dio;

  SubscriptionService(this.dio);

Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
  final response = await dio.get("/api/v1/subscriptions/plans/");

  dynamic body = response.data;

  // If API returns JSON string instead of decoded list
  if (body is String) {
    body = jsonDecode(body);
  }

  // Ensure it's a List
  if (body is List) {
    return body
        .map((e) => SubscriptionPlan.fromJson(e))
        .toList();
  }

  // If something unexpected comes
  throw Exception("Invalid subscription plan format");
}

  Future<ActiveSubscription?> subscribeToPlan(String planUuid) async {
    try {
      final response = await dio.post(
        '/api/v1/subscriptions/subscribe/',
        data: {'plan_uuid': planUuid},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ActiveSubscription.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<ActiveSubscription?> getActiveSubscription() async {
    try {
      final response = await dio.get('/api/v1/subscriptions/me/');
      if (response.statusCode == 200) {
        return ActiveSubscription.fromJson(response.data);
      }
      return null;
    } catch (e) {
      // If 404, it might mean no active subscription
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}
