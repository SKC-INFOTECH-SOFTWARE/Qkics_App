import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:q_kics/booking/models/booking.dart';
import 'package:q_kics/booking/models/expert_model.dart';
import 'package:q_kics/booking/models/expert_slot.dart';
import 'package:q_kics/booking/models/investor_slot.dart';
import 'package:q_kics/booking/models/investor_booking.dart';
import 'package:q_kics/booking/models/payment_model.dart';
import 'package:q_kics/providers/api_provider.dart';

class BookingApiService {
  final Dio dio;

  BookingApiService({Dio? dio}) : dio = dio ?? ApiProvider().dio;

  // ── Expert Slots ─────────────────────────────────────────────────────────

  Future<List<ExpertSlot>> getExpertSlots(String expertUuid) async {
    final response = await dio.get('/api/v1/bookings/experts/$expertUuid/slots/');
    return (response.data as List).map((e) => ExpertSlot.fromJson(e)).toList();
  }

  Future<void> createSlot({
    required DateTime start,
    required DateTime end,
    required int duration,
    required double chatPrice,
    required double videoCallPrice,
    required bool isChatAvailable,
    required bool isVideoCallAvailable,     
    required bool requiresApproval,
  }) async {
    final payload = {
      'start_datetime': start.toIso8601String(),
      'end_datetime': end.toIso8601String(),
      'duration_minutes': duration,
      'chat_price': chatPrice.toStringAsFixed(2),
      'video_call_price': videoCallPrice.toStringAsFixed(2),
      'is_chat_available': isChatAvailable,
      'is_video_call_available': isVideoCallAvailable,
      'requires_approval': requiresApproval,
    };
    debugPrint('📤 CREATE SLOT PAYLOAD: $payload');

    final response = await dio.post(
      '/api/v1/bookings/experts/slots/',
      data: payload,
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    debugPrint('✅ CREATE SLOT: ${response.statusCode} ${response.data}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.data);
    }
  }

  Future<void> updateSlot({
    required String slotUuid,
    required DateTime start,
    required DateTime end,
    required double chatPrice,
    required double videoCallPrice,
    required bool isChatAvailable,
    required bool isVideoCallAvailable,
    required bool requiresApproval,
  }) async {
    final payload = {
      'start_datetime': start.toIso8601String(),
      'end_datetime': end.toIso8601String(),
      'chat_price': chatPrice.toStringAsFixed(2),
      'video_call_price': videoCallPrice.toStringAsFixed(2),
      'is_chat_available': isChatAvailable,
      'is_video_call_available': isVideoCallAvailable,
      'requires_approval': requiresApproval,
    };
    debugPrint('📤 UPDATE SLOT PAYLOAD: $payload');

    await dio.patch(
      '/api/v1/bookings/experts/slots/$slotUuid/',
      data: payload,
    );
  }

  Future<void> deleteSlot(String slotUuid) async {
    await dio.delete('/api/v1/bookings/experts/slots/$slotUuid/delete/');
  }

  // ── Investor Slots ───────────────────────────────────────────────────────

  Future<List<InvestorSlot>> getInvestorSlots(String investorId) async {
    final response = await dio.get('/api/v1/bookings/investors/$investorId/slots/');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['results'] as List? ?? []).map((e) => InvestorSlot.fromJson(e)).toList();
    }
    if (data is List) return data.map((e) => InvestorSlot.fromJson(e)).toList();
    throw Exception('Unexpected investor slots response format');
  }

  Future<void> createInvestorSlot({
    required DateTime start,
    required DateTime end,
    required int duration,
  }) async {
    final payload = {
      'start_datetime': start.toIso8601String(),
      'end_datetime': end.toIso8601String(),
      'duration_minutes': duration,
    };
    final response = await dio.post(
      '/api/v1/bookings/investors/slots/',
      data: payload,
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.data);
    }
  }

  // ── Experts ──────────────────────────────────────────────────────────────

  Future<List<ExpertModel>> getExperts() async {
    final response = await dio.get('/api/v1/experts/');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['results'] as List? ?? []).map((e) => ExpertModel.fromJson(e)).toList();
    }
    throw Exception('Invalid experts response format');
  }

  // ── Expert Bookings ──────────────────────────────────────────────────────

  /// Books an expert slot. [sessionType] must be "CHAT" or "VIDEO_CALL".
  Future<Booking> createBooking(String slotUuid, String sessionType) async {
    debugPrint('📤 CREATE BOOKING: slot=$slotUuid sessionType=$sessionType');
    final response = await dio.post(
      '/api/v1/bookings/',
      data: {'slot_id': slotUuid, 'session_type': sessionType},
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    debugPrint('✅ BOOKING RESPONSE: ${response.statusCode} ${response.data}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.data);
    }
    return Booking.fromJson(response.data);
  }

  Future<List<Booking>> getBookings() async {
    final response = await dio.get('/api/v1/bookings/');
    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<List<Booking>> getExpertBookings() async {
    final response = await dio.get(
      '/api/v1/bookings/',
      queryParameters: {'as_expert': 'true'},
    );
    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<PaymentResponse> createBookingPayment(String bookingId) async {
    debugPrint('📤 CREATE PAYMENT: bookingId=$bookingId');
    final response = await dio.post(
      '/api/v1/payments/fake/booking/',
      data: {'booking_id': bookingId},
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    debugPrint('✅ PAYMENT RESPONSE: ${response.statusCode} ${response.data}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.data);
    }
    return PaymentResponse.fromJson(response.data);
  }

  // ── Investor Bookings ────────────────────────────────────────────────────

  Future<InvestorBooking> createInvestorBooking(String slotUuid) async {
    final response = await dio.post(
      '/api/v1/bookings/investor-bookings/',
      data: {'slot_id': slotUuid},
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(response.data);
    }
    return InvestorBooking.fromJson(response.data);
  }

  Future<List<InvestorBooking>> getInvestorBookings({bool asInvestor = false}) async {
    final response = await dio.get(
      '/api/v1/bookings/investor-bookings/list/',
      queryParameters: asInvestor ? {'as_investor': 'true'} : null,
    );
    return (response.data as List).map((e) => InvestorBooking.fromJson(e)).toList();
  }
}
