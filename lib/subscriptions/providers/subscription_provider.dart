// lib/subscriptions/providers/subscription_provider.dart
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

  Future<void> fetchPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plans = await _service.getSubscriptionPlans();
    } catch (e) {
      _error = e.toString();
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
      _error = e.toString();
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
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
