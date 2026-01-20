class Booking {
  final int id;
  final String uuid;
  final int user;
  final String userName;
  final int expert;
  final String expertName;
  final int slot;
  final String slotUuid;
  final String status;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final int durationMinutes;
  final double price;
  final double platformFeePercent;
  final double platformFeeAmount;
  final double expertEarningAmount;
  final bool requiresExpertApproval;
  final DateTime? expertApprovedAt;
  final DateTime? paidAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? declinedAt;
  final DateTime? cancelledAt;
  final int? chatRoomId;
  final int rescheduleCount;
  final String? cancellationReason;
  final String? declineReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool canBeCancelled;

  Booking({
    required this.id,
    required this.uuid,
    required this.user,
    required this.userName,
    required this.expert,
    required this.expertName,
    required this.slot,
    required this.slotUuid,
    required this.status,
    required this.startDatetime,
    required this.endDatetime,
    required this.durationMinutes,
    required this.price,
    required this.platformFeePercent,
    required this.platformFeeAmount,
    required this.expertEarningAmount,
    required this.requiresExpertApproval,
    this.expertApprovedAt,
    this.paidAt,
    this.confirmedAt,
    this.completedAt,
    this.declinedAt,
    this.cancelledAt,
    this.chatRoomId,
    required this.rescheduleCount,
    this.cancellationReason,
    this.declineReason,
    required this.createdAt,
    required this.updatedAt,
    required this.canBeCancelled,
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: int.parse(json['id'].toString()),
      uuid: json['uuid'],
      user: int.parse(json['user'].toString()),
      userName: json['user_name'],
      expert: int.parse(json['expert'].toString()),
      expertName: json['expert_name'],
      slot: int.parse(json['slot'].toString()),
      slotUuid: json['slot_uuid'],
      status: json['status'],
      startDatetime: DateTime.parse(json['start_datetime']),
      endDatetime: DateTime.parse(json['end_datetime']),
      durationMinutes: int.parse(json['duration_minutes'].toString()),
      price: double.parse(json['price'].toString()),
      platformFeePercent: double.parse(json['platform_fee_percent'].toString()),
      platformFeeAmount: double.parse(json['platform_fee_amount'].toString()),
      expertEarningAmount: double.parse(
        json['expert_earning_amount'].toString(),
      ),
      requiresExpertApproval: json['requires_expert_approval'],
      expertApprovedAt: json['expert_approved_at'] != null
          ? DateTime.parse(json['expert_approved_at'])
          : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      declinedAt: json['declined_at'] != null
          ? DateTime.parse(json['declined_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      chatRoomId: _parseInt(json['chat_room_id']),
      rescheduleCount: int.parse(json['reschedule_count'].toString()),
      cancellationReason: json['cancellation_reason'],
      declineReason: json['decline_reason'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      canBeCancelled: json['can_be_cancelled'],
    );
  }

  // Helper getters for UI
  bool get isPending => status == 'PENDING';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isDeclined => status == 'DECLINED';
  bool get isCancelled => status == 'CANCELLED';
}
