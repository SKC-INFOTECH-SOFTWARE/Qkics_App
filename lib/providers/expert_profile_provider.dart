import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:q_kics/profile/models/expert/expert_profile_model.dart';
import 'package:q_kics/profile/services/expert_api_service.dart';

class ExpertProfileProvider extends ChangeNotifier {
  final ExpertApiService api;
  ExpertProfileProvider(this.api);

  ExpertProfile? profile;
  bool exists = false;

  bool _profileLoading = false;
  bool get profileLoading => _profileLoading;

  bool _disposed = false;
  bool get mounted => !_disposed;
bool _initialized = false;
bool get initialized => _initialized;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (mounted) super.notifyListeners();
  }

  bool actionLoading = false;
  String? get expertUuid => profile?.uuid;

  List<Map<String, dynamic>> experiences = [];
  List<Map<String, dynamic>> educations = [];
  List<Map<String, dynamic>> certifications = [];
  List<Map<String, dynamic>> honors = [];

  bool get hasDraft => profile != null && profile!.applicationStatus == 'draft';

  bool get isPending =>
      profile != null && profile!.applicationStatus == 'pending';

  Future<void> fetchExpertProfile() async {
  if (_profileLoading) return;

  _profileLoading = true;

  try {
    final data = await api.getMyExpertProfile();

    profile = ExpertProfile.fromJson(data);
    exists = true;

    experiences =
        List<Map<String, dynamic>>.from(data['experiences'] ?? []);
    educations =
        List<Map<String, dynamic>>.from(data['educations'] ?? []);
    certifications =
        List<Map<String, dynamic>>.from(data['certifications'] ?? []);
    honors =
        List<Map<String, dynamic>>.from(data['honors_awards'] ?? []);

  } on DioException catch (e) {
    // ✅ 404 = No profile yet (Create mode)
    if (e.response?.statusCode == 404) {
      profile = null;
      exists = false;
    } else {
      debugPrint('Fetch error: ${e.response?.data}');
    }
  } catch (e) {
    debugPrint('Unexpected fetch error: $e');
  } finally {
    _profileLoading = false;
    _initialized = true;   // 🔥 VERY IMPORTANT
    notifyListeners();
  }
}



  // ============================================================
  // CREATE / UPDATE PROFILE
  // ============================================================
  Future<void> createOrUpdateProfile(Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();
    try {
      profile = profile == null
          ? await api.createProfile(data)
          : await api.updateProfile(data);
    } on DioException catch (e) {
      debugPrint('❌ Expert profile error: ${e.response?.data}');
      rethrow;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SUBMIT FOR REVIEW
  // ============================================================
  Future<void> submitForExpertReview({String? note}) async {
    actionLoading = true;
    notifyListeners();

    try {
      await api.submitForReview(
        note ?? 'Submitting expert profile for admin review',
      );

      await fetchExpertProfile();
    } catch (e) {
      debugPrint("Expert submission failed (already handled globally): $e");
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // EXPERIENCE
  // ============================================================
  Future<void> addExperience(Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();
    try {
      final created = await api.addExperience(data);
      experiences.add(created); // ✅ LOCAL UPDATE ONLY
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExperience(int id, Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();
    try {
      final res = await api.updateExperience(id, data);
      final index = experiences.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(res.data);
        updated['id'] = id;
        experiences[index] = updated;
      }
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExperience(int id) async {
    actionLoading = true;
    notifyListeners();
    try {
      await api.deleteExperience(id);
      experiences.removeWhere((e) => e['id'] == id);
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // EDUCATION
  // ============================================================
  Future<void> addEducation(Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();

    try {
      final res = await api.addEducation(data);

      // ✅ ALWAYS USE res.data
      educations.add(Map<String, dynamic>.from(res.data));
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEducation(int id, Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();
    try {
      final res = await api.updateEducation(id, data);
      final index = educations.indexWhere((e) => e['id'] == id);
      if (index != -1) educations[index] = res.data;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEducation(int id) async {
    actionLoading = true;
    notifyListeners();
    try {
      await api.deleteEducation(id);
      educations.removeWhere((e) => e['id'] == id);
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CERTIFICATION
  // ============================================================
  Future<void> addCertification(Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();
    try {
      final created = await api.addCertification(data);
      certifications.add(created as Map<String, dynamic>);
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCertification(int id, Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();
    try {
      final res = await api.updateCertification(id, data);
      final index = certifications.indexWhere((e) => e['id'] == id);
      if (index != -1) certifications[index] = res.data;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCertification(int id) async {
    actionLoading = true;
    notifyListeners();
    try {
      await api.deleteCertification(id);
      certifications.removeWhere((e) => e['id'] == id);
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // HONOR
  // ============================================================
  Future<void> addHonor(Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();
    try {
      final created = await api.addHonor(data);
      honors.add(created as Map<String, dynamic>);
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHonor(int id, Map<String, dynamic> data) async {
    actionLoading = true;
    notifyListeners();
    try {
      final res = await api.updateHonor(id, data);
      final index = honors.indexWhere((e) => e['id'] == id);
      if (index != -1) honors[index] = res.data;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteHonor(int id) async {
    actionLoading = true;
    notifyListeners();
    try {
      await api.deleteHonor(id);
      honors.removeWhere((e) => e['id'] == id);
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }
}
