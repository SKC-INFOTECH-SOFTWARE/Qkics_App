class ExpertSlot {
  final int id;
  final String uuid;
  final String expertName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final double price;
  final bool requiresApproval;
  final bool isAvailable;

  ExpertSlot({
    required this.id,
    required this.uuid,
    required this.expertName,
    required this.startDateTime,
    required this.endDateTime,
    required this.durationMinutes,
    required this.price,
    required this.requiresApproval,
    required this.isAvailable,
  });

  factory ExpertSlot.fromJson(Map<String, dynamic> json) {
    return ExpertSlot(
      id: json['id'],
      uuid: json['uuid'],
      expertName: json['expert_name'],
      startDateTime: DateTime.parse(json['start_datetime']),
      endDateTime: DateTime.parse(json['end_datetime']),
      durationMinutes: json['duration_minutes'],
      price: double.parse(json['price']),
      requiresApproval: json['requires_approval'],
      isAvailable: json['is_available'],
    );
  }
}
