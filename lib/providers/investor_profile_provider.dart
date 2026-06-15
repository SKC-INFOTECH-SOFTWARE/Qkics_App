import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:q_kics/profile/models/investor/investor_profile.dart';

class InvestorProfileProvider extends ChangeNotifier {
  final Dio dio;

  InvestorProfile? _profile;
  bool isLoading = false;
  String? errorMessage;

  InvestorProfile? get profile => _profile;
  bool get exists => _profile != null;

  /// Returns the best identifier for API calls (uuid if available, otherwise id)
  String? get investorIdentifier {
    if (_profile == null) return null;
    if (_profile!.uuid.isNotEmpty) return _profile!.uuid;
    return _profile!.id.toString();
  }

  bool _disposed = false;
  bool get mounted => !_disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (mounted) super.notifyListeners();
  }

  InvestorProfileProvider(this.dio);

  // ───────────────────────────
  // FETCH INVESTOR PROFILE
  // ───────────────────────────
  Future<void> fetchMyProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await dio.get('/api/v1/investors/me/profile/');
      debugPrint("📡 INVESTOR PROFILE RAW DATA: ${res.data}");
      _profile = InvestorProfile.fromJson(res.data);
      debugPrint(
        "✅ INVESTOR PROFILE PARSED: id=${_profile!.id}, uuid='${_profile!.uuid}', name=${_profile!.displayName}",
      );
    } on DioException catch (e) {
      // ✅ EXPECTED CASE: No investor profile yet
      if (e.response?.statusCode == 404) {
        _profile = null;
      } else {
        errorMessage =
            e.response?.data.toString() ?? 'Failed to load investor profile';
        debugPrint(
          "Investor profile fetch error: ${e.response?.data ?? e.message}",
        );
      }
    } catch (e) {
      debugPrint("Investor profile load failed (already handled globally): $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────────────────
  // UPDATE INVESTOR PROFILE
  // ───────────────────────────
  Future<void> updateProfile(Map<String, dynamic> payload) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await dio.patch(
        '/api/v1/investors/me/profile/',
        data: payload,
      );

      _profile = InvestorProfile.fromJson(res.data);
    } on DioException catch (e) {
      errorMessage =
          e.response?.data.toString() ?? 'Failed to update investor profile';
      debugPrint(
        "Investor profile update error: ${e.response?.data ?? e.message}",
      );
      rethrow; // UI can show snackbar
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}
