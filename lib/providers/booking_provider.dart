import 'package:flutter/material.dart';
import 'package:q_kics/booking/booking_api_service.dart';
import 'package:q_kics/booking/models/booking.dart';
import 'package:q_kics/booking/models/expert_model.dart';
import 'package:q_kics/booking/models/expert_slot.dart';

class BookingProvider extends ChangeNotifier {
  final BookingApiService _api = BookingApiService();

  String? _expertUuid; // 🔑 SINGLE SOURCE OF TRUTH

  List<ExpertSlot> slots = [];
  bool isLoading = false;
  String? error;
  List<ExpertModel> experts = [];

  // Booking lists
  List<Booking> userBookings = [];
  List<Booking> expertBookings = [];
  bool isLoadingBookings = false;
  String? bookingsError;
  // ================= SET UUID =================
  void setExpertUuid(String uuid) {
    _expertUuid = uuid;
    debugPrint("✅ expertUuid set: $_expertUuid");
  }

  // ================= FETCH SLOTS =================
  Future<void> fetchSlots() async {
    if (_expertUuid == null) {
      debugPrint("❌ fetchSlots aborted: expertUuid is null");
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      debugPrint(
        "📡 GET SLOTS URL: ${_api.dio.options.baseUrl}/api/v1/bookings/experts/$_expertUuid/slots/",
      );

      slots = await _api.getExpertSlots(_expertUuid!);
    } catch (e) {
      debugPrint("❌ fetchSlots error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExperts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      experts = await _api.getExperts();
    } catch (e) {
      error = "Failed to load experts";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= CREATE SLOT =================
  Future<void> createSlot({
    required DateTime start,
    required DateTime end,
    required int duration,
    required double price,
    required bool requiresApproval,
  }) async {
    if (_expertUuid == null) {
      throw Exception("expertUuid not set");
    }

    try {
      isLoading = true;
      notifyListeners();

      await _api.createSlot(
        start: start,
        end: end,
        duration: duration,
        price: price,
        requiresApproval: requiresApproval,
      );

      // 🔁 refresh after create
      await fetchSlots();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= UPDATE SLOT =================
  Future<void> updateSlot({
    required String slotUuid,
    required DateTime start,
    required DateTime end,
    required double price,
    required bool requiresApproval,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      await _api.updateSlot(
        slotUuid: slotUuid,
        start: start,
        end: end,
        price: price,
        requiresApproval: requiresApproval,
      );

      await fetchSlots();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= DELETE SLOT =================
  Future<void> deleteSlot(String slotUuid) async {
    try {
      isLoading = true;
      notifyListeners();

      await _api.deleteSlot(slotUuid);
      await fetchSlots();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= FETCH USER BOOKINGS =================
  Future<void> fetchUserBookings() async {
    try {
      isLoadingBookings = true;
      bookingsError = null;
      notifyListeners();

      userBookings = await _api.getBookings();
    } catch (e) {
      debugPrint("❌ fetchUserBookings error: $e");
      bookingsError = "Failed to load bookings";
    } finally {
      isLoadingBookings = false;
      notifyListeners();
    }
  }

  // ================= FETCH EXPERT BOOKINGS =================
  Future<void> fetchExpertBookings() async {
    try {
      isLoadingBookings = true;
      bookingsError = null;
      notifyListeners();

      expertBookings = await _api.getExpertBookings();
    } catch (e) {
      debugPrint("❌ fetchExpertBookings error: $e");
      bookingsError = "Failed to load expert bookings";
    } finally {
      isLoadingBookings = false;
      notifyListeners();
    }
  }
}
