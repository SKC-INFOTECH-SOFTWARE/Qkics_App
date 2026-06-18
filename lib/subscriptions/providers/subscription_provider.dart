// lib/subscriptions/providers/subscription_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';
import '../models/active_subscription.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _service;

  SubscriptionProvider(this._service);

  List<SubscriptionPlan> _plans = [];
  ActiveSubscription? _activeSubscription;
  bool _isLoading = false;
  String? _error;

  List<SubscriptionPlan> get plans => _plans;
  ActiveSubscription? get activeSubscription => _activeSubscription;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Extracts a human-readable message from an API error, falling back to a
  /// friendly default instead of leaking raw exceptions / status codes.
  String _messageFromError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        for (final key in ['detail', 'error', 'message']) {
          final value = data[key];
          if (value != null && value.toString().isNotEmpty) {
            return value.toString();
          }
        }
        for (final value in data.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String && value.isNotEmpty) return value;
        }
      }
      if (data is String && data.isNotEmpty) return data;
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> fetchPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plans = await _service.getSubscriptionPlans();
    } catch (e) {
      _error = _messageFromError(e);
      debugPrint("Error fetching subscription plans: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActiveSubscription() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeSubscription = await _service.getActiveSubscription();
    } catch (e) {
      _error = _messageFromError(e);
      debugPrint("Error fetching active subscription: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> subscribe(String planUuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final subscription = await _service.subscribeToPlan(planUuid);
      if (subscription != null) {
        _activeSubscription = subscription;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = _messageFromError(e);
      debugPrint("Error subscribing to plan: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
