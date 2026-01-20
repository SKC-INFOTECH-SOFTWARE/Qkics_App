import 'package:dio/dio.dart';
import 'package:q_kics/booking/models/booking.dart';
import 'package:q_kics/booking/models/expert_model.dart';
import 'package:q_kics/booking/models/expert_slot.dart';
import 'package:q_kics/booking/models/payment_model.dart';
import 'package:q_kics/providers/api_provider.dart';

class BookingApiService {
  final Dio dio;

  // 👇 Inject Dio from ApiProvider
  BookingApiService({Dio? dio}) : dio = dio ?? ApiProvider().dio;

  /// GET Expert Slots (Public)
  Future<List<ExpertSlot>> getExpertSlots(String expertUuid) async {
    final url = "/api/v1/bookings/experts/$expertUuid/slots/";
    print("📡 GET SLOTS URL: ${dio.options.baseUrl}$url");

    final response = await dio.get(url);

    return (response.data as List).map((e) => ExpertSlot.fromJson(e)).toList();
  }

  /// CREATE Slot (Expert - Auth required)
  Future<void> createSlot({
    required DateTime start,
    required DateTime end,
    required int duration,
    required double price,
    required bool requiresApproval,
  }) async {
    final payload = {
      "start_datetime": start.toIso8601String(),
      "end_datetime": end.toIso8601String(),
      "duration_minutes": duration,
      "price": price.toStringAsFixed(2),
      "requires_approval": requiresApproval,
    };

    print("📤 CREATE SLOT PAYLOAD: $payload");

    try {
      final response = await dio.post(
        "/api/v1/bookings/experts/slots/",
        data: payload,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print("✅ RESPONSE STATUS: ${response.statusCode}");
      print("✅ RESPONSE BODY: ${response.data}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data);
      }
    } on DioException catch (e) {
      print("❌ DIO ERROR STATUS: ${e.response?.statusCode}");
      print("❌ DIO ERROR BODY: ${e.response?.data}");
      rethrow;
    }
  }

  Future<List<ExpertModel>> getExperts() async {
    final response = await dio.get("/api/v1/experts/");

    return (response.data as List).map((e) => ExpertModel.fromJson(e)).toList();
  }

  Future<void> updateSlot({
    required String slotUuid,
    required DateTime start,
    required DateTime end,
    required double price,
    required bool requiresApproval,
  }) async {
    await dio.patch(
      "/api/v1/bookings/experts/slots/$slotUuid/",
      data: {
        "start_datetime": start.toIso8601String(),
        "end_datetime": end.toIso8601String(),
        "price": price.toStringAsFixed(2),
        "requires_approval": requiresApproval,
        "status": "ACTIVE",
      },
    );
  }

  Future<void> deleteSlot(String slotUuid) async {
    await dio.delete("/api/v1/bookings/experts/slots/$slotUuid/delete/");
  }

  /// GET User Bookings (Auth required)
  Future<List<Booking>> getBookings() async {
    final response = await dio.get("/api/v1/bookings/");

    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  /// CREATE Booking (User books a slot)
  Future<Booking> createBooking(String slotUuid) async {
    final url = "/api/v1/bookings/";
    print("📡 POST BOOKING URL: ${dio.options.baseUrl}$url");
    print("📤 SLOT UUID: $slotUuid");

    try {
      final response = await dio.post(
        url,
        data: {"slot_id": slotUuid},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print("✅ BOOKING RESPONSE STATUS: ${response.statusCode}");
      print("✅ BOOKING RESPONSE BODY: ${response.data}");
      print("✅ BOOKING RESPONSE HEADERS: ${response.headers}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data);
      }

      // 🚨 API only returns price, so we can't parse full Booking object yet.
      // We need to find where the ID is.
      // If the ID is not in the body, check 'Location' header or similar.

      // For now, let's try to extract ID from headers or fallback to null (which will crash later if we don't handle it)
      // But to avoid the immediate JSON parse error, we'll return a DUMMY booking or partial one.

      // NOTE: This is a TEMPORARY fix to see the headers. The real fix depends on where the ID is.
      // If the response is just price, maybe the booking isn't created yet?
      // Or maybe the ID is in the 'id' field of the response but it's null?

      // Let's inspect the data manually first:
      final data = response.data;
      if (data is Map<String, dynamic> &&
          !data.containsKey('id') &&
          !data.containsKey('uuid')) {
        print(
          "⚠️ WARNING: API returned partial data (Price only?). Cannot create full Booking object.",
        );
        // If we can't get an ID, we can't proceed to payment.
        // Throwing a more descriptive error for the user to see in the UI.
        throw Exception(
          "API returned incomplete booking data: $data. Expected 'uuid'.",
        );
      }

      return Booking.fromJson(response.data);
    } on DioException catch (e) {
      print("❌ BOOKING DIO ERROR STATUS: ${e.response?.statusCode}");
      print("❌ BOOKING DIO ERROR BODY: ${e.response?.data}");
      rethrow;
    }
  }

  /// GET Expert Bookings (Auth required)
  Future<List<Booking>> getExpertBookings() async {
    final response = await dio.get(
      "/api/v1/bookings/",
      queryParameters: {"as_expert": "true"},
    );

    return (response.data as List).map((e) => Booking.fromJson(e)).toList();
  }

  /// CREATE Booking Payment (Fake Payment)
  Future<PaymentResponse> createBookingPayment(String bookingId) async {
    final url = "/api/v1/payments/fake/booking/";
    print("📡 POST PAYMENT URL: ${dio.options.baseUrl}$url");
    print("📤 BOOKING ID: $bookingId");

    try {
      final response = await dio.post(
        url,
        data: {"booking_id": bookingId},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print("✅ PAYMENT RESPONSE STATUS: ${response.statusCode}");
      print("✅ PAYMENT RESPONSE BODY: ${response.data}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data);
      }

      return PaymentResponse.fromJson(response.data);
    } on DioException catch (e) {
      print("❌ PAYMENT DIO ERROR STATUS: ${e.response?.statusCode}");
      print("❌ PAYMENT DIO ERROR BODY: ${e.response?.data}");
      rethrow;
    }
  }
}
