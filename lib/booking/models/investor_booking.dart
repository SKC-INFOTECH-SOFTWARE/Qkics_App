class InvestorBooking {
  final int id;
  final String uuid;
  final int user;
  final String userName;
  final int investor;
  final String investorName;
  final int slot;
  final String status;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final int rescheduleCount;
  final DateTime createdAt;
  final String? callRoomId;

  InvestorBooking({
    required this.id,
    required this.uuid,
    required this.user,
    required this.userName,
    required this.investor,
    required this.investorName,
    required this.slot,
    required this.status,
    required this.startDateTime,
    required this.endDateTime,
    required this.durationMinutes,
    required this.rescheduleCount,
    required this.createdAt,
    this.callRoomId,
  });

  factory InvestorBooking.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['start_datetime']);
    final end = DateTime.parse(json['end_datetime']);
    final computedDuration = end.difference(start).inMinutes;
    return InvestorBooking(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      user: json['user'] ?? 0,
      userName: json['user_name'] ?? '',
      investor: json['investor'] ?? 0,
      investorName: json['investor_name'] ?? '',
      slot: json['slot'] ?? 0,
      status: json['status'] ?? '',
      startDateTime: start,
      endDateTime: end,
      durationMinutes: json['duration_minutes'] ?? computedDuration,
      rescheduleCount: json['reschedule_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      callRoomId: json['call_room_id']?.toString(),
    );
  }
}
