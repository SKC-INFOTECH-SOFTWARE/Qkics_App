class ExpertSlot {
  final int id;
  final String uuid;
  final String expertName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final double chatPrice;
  final double videoCallPrice;
  final bool requiresApproval;
  final bool isChatAvailable;
  final bool isVideoCallAvailable;

  ExpertSlot({
    required this.id,
    required this.uuid,
    required this.expertName,
    required this.startDateTime,
    required this.endDateTime,
    required this.durationMinutes,
    required this.chatPrice,
    required this.videoCallPrice,
    required this.requiresApproval,
    required this.isChatAvailable,
    required this.isVideoCallAvailable,
  });

  bool get isAvailable => isChatAvailable || isVideoCallAvailable;
  bool get isBooked => !isChatAvailable && !isVideoCallAvailable;

  factory ExpertSlot.fromJson(Map<String, dynamic> json) {
    return ExpertSlot(
      id: json['id'],
      uuid: json['uuid'],
      expertName: json['expert_name'] ?? '',
      startDateTime: DateTime.parse(json['start_datetime']),
      endDateTime: DateTime.parse(json['end_datetime']),
      durationMinutes: json['duration_minutes'],
      chatPrice: double.parse((json['chat_price'] ?? '0').toString()),
      videoCallPrice: double.parse((json['video_call_price'] ?? '0').toString()),
      requiresApproval: json['requires_approval'] ?? false,
      isChatAvailable: json['is_chat_available'] ?? false,
      isVideoCallAvailable: json['is_video_call_available'] ?? false,
    );
  }
}
