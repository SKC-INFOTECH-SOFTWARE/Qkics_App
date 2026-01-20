import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:q_kics/profile/models/entrepreneur/entrepreneur_profile_model.dart';

class EntrepreneurApiService {
  final Dio dio;
  EntrepreneurApiService(this.dio);

  // ================= CREATE =================
  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> data) async {
    final res = await dio.post('/api/v1/entrepreneurs/me/profile/', data: data);
    return res.data;
  }

  // ================= FETCH =================
  /// ⚠️ IMPORTANT:
  /// 404 = profile does not exist (EXPECTED)
  Future<Map<String, dynamic>> getMyEntrepreneurProfile() async {
    final res = await dio.get('/api/v1/entrepreneurs/me/profile/');
    return res.data;
  }

  Future<List<EntrepreneurProfile>> getAllEntrepreneurs() async {
    final res = await dio.get('/api/v1/entrepreneurs/');
    return (res.data as List)
        .map((e) => EntrepreneurProfile.fromJson(e))
        .toList();
  }

  // ================= UPDATE =================
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await dio.patch(
      '/api/v1/entrepreneurs/me/profile/',
      data: data,
    );
    return res.data;
  }

  // ================= SUBMIT FOR REVIEW =================
  Future<void> submitForEntrepreneurReview(String note) async {
    await dio.post('/api/v1/entrepreneurs/me/submit/', data: {"note": note});
  }
}
