class Payment {
  final String uuid;
  final String purpose;
  final String referenceId;
  final double amount;
  final String status;
  final String gateway;
  final String? gatewayOrderId;
  final String? gatewayPaymentId;
  final DateTime createdAt;

  Payment({
    required this.uuid,
    required this.purpose,
    required this.referenceId,
    required this.amount,
    required this.status,
    required this.gateway,
    this.gatewayOrderId,
    this.gatewayPaymentId,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      uuid: json['uuid'],
      purpose: json['purpose'],
      referenceId: json['reference_id'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      gateway: json['gateway'],
      gatewayOrderId: json['gateway_order_id'],
      gatewayPaymentId: json['gateway_payment_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Helper getters
  bool get isSuccess => status == 'SUCCESS';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}

class PaymentResponse {
  final Payment payment;
  final String bookingId;
  final String chatRoomId;
  final String status;

  PaymentResponse({
    required this.payment,
    required this.bookingId,
    required this.chatRoomId,
    required this.status,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      payment: Payment.fromJson(json['payment']),
      bookingId: json['booking_id'],
      chatRoomId: json['chat_room_id'],
      status: json['status'],
    );
  }

  bool get isBookingConfirmed => status == 'BOOKING_CONFIRMED_AND_CHAT_CREATED';
}
