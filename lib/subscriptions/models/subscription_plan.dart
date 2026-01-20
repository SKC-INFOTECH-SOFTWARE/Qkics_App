// lib/subscriptions/models/subscription_plan.dart

class SubscriptionPlan {
  final String uuid;
  final String name;
  final double price;
  final int durationDays;
  final int premiumDocLimit;
  final int freeConsultationCount;
  final int freeChatPerMonth;
  final bool isActive;

  SubscriptionPlan({
    required this.uuid,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.premiumDocLimit,
    required this.freeConsultationCount,
    required this.freeChatPerMonth,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      durationDays: json['duration_days'] ?? 0,
      premiumDocLimit: json['premium_doc_limit_per_month'] ?? 0,
      freeConsultationCount: json['free_consultation_count'] ?? 0,
      freeChatPerMonth: json['free_chat_per_month'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'price': price.toString(),
      'duration_days': durationDays,
      'premium_doc_limit_per_month': premiumDocLimit,
      'free_consultation_count': freeConsultationCount,
      'free_chat_per_month': freeChatPerMonth,
      'is_active': isActive,
    };
  }
}
