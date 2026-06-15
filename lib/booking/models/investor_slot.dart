class InvestorSlot {
  final int id;
  final String uuid;
  final String investorName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final String status;
  final bool isAvailable;

  InvestorSlot({
    required this.id,
    required this.uuid,
    required this.investorName,
    required this.startDateTime,
    required this.endDateTime,
    required this.durationMinutes,
    required this.status,
    required this.isAvailable,
  });

  factory InvestorSlot.fromJson(Map<String, dynamic> json) {
    return InvestorSlot(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      investorName: json['investor_name'] ?? '',
      startDateTime: DateTime.parse(json['start_datetime']),
      endDateTime: DateTime.parse(json['end_datetime']),
      durationMinutes: json['duration_minutes'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
      isAvailable: json['is_available'] ?? true,
    );
  }
}
