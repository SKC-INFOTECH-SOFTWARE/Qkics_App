import 'package:flutter/material.dart';
import 'package:q_kics/profile/models/entrepreneur/entrepreneur_profile_model.dart';
import '../profile/services/entrepreneur_api_service.dart';

class EntrepreneurProfileProvider extends ChangeNotifier {
  final EntrepreneurApiService api;

  EntrepreneurProfileProvider(this.api);

  bool loading = false;
  bool exists = false;
  EntrepreneurProfile? profile;

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

  // ================= STATUS HELPERS =================
  bool get hasDraft => profile != null && profile!.applicationStatus == 'draft';

  bool get isPending =>
      profile != null && profile!.applicationStatus == 'pending';

  bool get isApproved =>
      profile != null && profile!.applicationStatus == 'approved';
  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> loadProfile() async {
    loading = true;
    notifyListeners();

    try {
      final data = await api.getMyEntrepreneurProfile();

      // ✅ Convert Map → Model
      profile = EntrepreneurProfile.fromJson(data);
      exists = true;
    } catch (e) {
      // 404 or profile not created yet
      profile = null;
      exists = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEntrepreneurProfile() async {
    loading = true;
    notifyListeners();

    try {
      final data = await api.getMyEntrepreneurProfile();
      profile = EntrepreneurProfile.fromJson(data);
      exists = true;
    } catch (e) {
      exists = false;
      profile = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createOrUpdateProfile(Map<String, dynamic> data) async {
    loading = true;
    notifyListeners();

    try {
      final res = profile == null
          ? await api.createProfile(data)
          : await api.updateProfile(data);

      profile = EntrepreneurProfile.fromJson(res);
      exists = true;
    } catch (e) {
      debugPrint(
        "Entrepreneur profile update failed (already handled globally): $e",
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> submitForEntrepreneurReview({String? note}) async {
    loading = true;
    notifyListeners();

    try {
      await api.submitForEntrepreneurReview(
        note ?? 'Submitting entrepreneur profile for admin review',
      );

      await fetchEntrepreneurProfile();
    } catch (e) {
      debugPrint(
        "Entrepreneur submission failed (already handled globally): $e",
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
