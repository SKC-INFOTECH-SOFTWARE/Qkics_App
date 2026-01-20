// lib/subscriptions/models/active_subscription.dart
import 'subscription_plan.dart';

class ActiveSubscription {
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int premiumDocsUsedThisMonth;
  final int chatsUsedThisMonth;
  final bool freeConsultationUsed;
  final DateTime createdAt;

  ActiveSubscription({
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.premiumDocsUsedThisMonth,
    required this.chatsUsedThisMonth,
    required this.freeConsultationUsed,
    required this.createdAt,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      plan: SubscriptionPlan.fromJson(json['plan'] ?? {}),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] ?? false,
      premiumDocsUsedThisMonth: json['premium_docs_used_this_month'] ?? 0,
      chatsUsedThisMonth: json['chats_used_this_month'] ?? 0,
      freeConsultationUsed: json['free_consultation_used'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
