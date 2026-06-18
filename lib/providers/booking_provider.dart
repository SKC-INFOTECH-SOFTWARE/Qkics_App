import 'package:flutter/material.dart';
import 'package:q_kics/booking/booking_api_service.dart';
import 'package:q_kics/booking/models/booking.dart';
import 'package:q_kics/booking/models/expert_model.dart';
import 'package:q_kics/booking/models/expert_slot.dart';
import 'package:q_kics/booking/models/investor_slot.dart';
import 'package:q_kics/booking/models/investor_booking.dart';

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

  // Investor specific state
  String? _investorUuid;
  List<InvestorSlot> investorSlots = [];
  List<InvestorBooking> userInvestorBookings = [];
  List<InvestorBooking> investorAsInvestorBookings = [];
  // ================= SET UUID =================
  void setExpertUuid(String uuid) {
    _expertUuid = uuid;
    debugPrint("✅ expertUuid set: $_expertUuid");
  }

  void setInvestorUuid(String uuid) {
    _investorUuid = uuid;
    debugPrint("✅ investorUuid set: $_investorUuid");
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

  Future<void> fetchExperts({String? search}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      experts = await _api.getExperts(search: search);
    } catch (e) {
      error = "Failed to load experts";
      debugPrint('❌ fetchExperts error: $e');
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
    required double chatPrice,
    required double videoCallPrice,
    required bool isChatAvailable,
    required bool isVideoCallAvailable,
    required bool requiresApproval,
  }) async {
    if (_expertUuid == null) throw Exception('expertUuid not set');
    try {
      isLoading = true;
      notifyListeners();
      await _api.createSlot(
        start: start,
        end: end,
        duration: duration,
        chatPrice: chatPrice,
        videoCallPrice: videoCallPrice,
        isChatAvailable: isChatAvailable,
        isVideoCallAvailable: isVideoCallAvailable,
        requiresApproval: requiresApproval,
      );
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
    required double chatPrice,
    required double videoCallPrice,
    required bool isChatAvailable,
    required bool isVideoCallAvailable,
    required bool requiresApproval,
  }) async {
    try {
      isLoading = true;
      notifyListeners();
      await _api.updateSlot(
        slotUuid: slotUuid,
        start: start,
        end: end,
        chatPrice: chatPrice,
        videoCallPrice: videoCallPrice,
        isChatAvailable: isChatAvailable,
        isVideoCallAvailable: isVideoCallAvailable,
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

  // ================= INVESTOR METHODS =================

  Future<void> fetchInvestorSlots() async {
    if (_investorUuid == null) return;

    try {
      isLoading = true;
      notifyListeners();
      investorSlots = await _api.getInvestorSlots(_investorUuid!);
    } catch (e) {
      debugPrint("❌ fetchInvestorSlots error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createInvestorSlot({
    required DateTime start,
    required DateTime end,
    required int duration,
  }) async {
    try {
      isLoading = true;
      notifyListeners();
      await _api.createInvestorSlot(start: start, end: end, duration: duration);
      await fetchInvestorSlots();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createInvestorBooking(String slotUuid) async {
    try {
      isLoading = true;
      notifyListeners();
      await _api.createInvestorBooking(slotUuid);
    } catch (e) {
      debugPrint("❌ createInvestorBooking error: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserInvestorBookings() async {
    try {
      isLoadingBookings = true;
      bookingsError = null;
      notifyListeners();
      userInvestorBookings = await _api.getInvestorBookings();
    } catch (e) {
      debugPrint("❌ fetchUserInvestorBookings error: $e");
      bookingsError = "Failed to load investor bookings";
    } finally {
      isLoadingBookings = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvestorAsInvestorBookings() async {
    try {
      isLoadingBookings = true;
      bookingsError = null;
      notifyListeners();
      investorAsInvestorBookings = await _api.getInvestorBookings(
        asInvestor: true,
      );
    } catch (e) {
      debugPrint("❌ fetchInvestorAsInvestorBookings error: $e");
      bookingsError = "Failed to load investor bookings";
    } finally {
      isLoadingBookings = false;
      notifyListeners();
    }
  }
}
