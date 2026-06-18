import 'package:dio/dio.dart';
import 'package:q_kics/profile/models/expert/expert_profile_model.dart';

class ExpertApiService {
  final Dio dio;
  ExpertApiService(this.dio);

  Future<ExpertProfile> createProfile(Map<String, dynamic> data) async {
    final res = await dio.post('/api/v1/experts/me/profile/', data: data);
    return ExpertProfile.fromJson(res.data);
  }

  Future<ExpertProfile> updateProfile(Map<String, dynamic> data) async {
    final res = await dio.put('/api/v1/experts/me/profile/', data: data);
    return ExpertProfile.fromJson(res.data);
  }

  Future<Map<String, dynamic>> getMyExpertProfile() async {
    final res = await dio.get('/api/v1/experts/me/profile/');
    return res.data;
  }

Future<List<ExpertProfile>> getAllExperts({String? search}) async {
  final res = await dio.get(
    '/api/v1/experts/',
    queryParameters: (search != null && search.isNotEmpty) ? {'search': search} : null,
  );

  final data = res.data as Map<String, dynamic>;
  final List<dynamic> results = data['results'];

  return results
      .map((e) => ExpertProfile.fromJson(e as Map<String, dynamic>))
      .toList();
}

  Future<void> submitForReview(String note) async {
    await dio.post('/api/v1/experts/me/submit/', data: {"note": note});
  }

  // Experience / Education / Certification / Honors handled similarly
  // EXPERIENCE
  Future<Map<String, dynamic>> addExperience(Map<String, dynamic> data) async {
    final res = await dio.post('/api/v1/experts/experience/', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  Future<Response> updateExperience(int id, Map<String, dynamic> data) =>
      dio.put('/api/v1/experts/experience/$id/', data: data);

  Future<Response> deleteExperience(int id) =>
      dio.delete('/api/v1/experts/experience/$id/');

  // EDUCATION
  Future<Response> addEducation(Map<String, dynamic> data) =>
      dio.post('/api/v1/experts/education/', data: data);

  Future<Response> updateEducation(int id, Map<String, dynamic> data) =>
      dio.put('/api/v1/experts/education/$id/', data: data);

  Future<Response> deleteEducation(int id) =>
      dio.delete('/api/v1/experts/education/$id/');
  // CERTIFICATION
  Future<Response> addCertification(Map<String, dynamic> data) =>
      dio.post('/api/v1/experts/certifications/', data: data);

  Future<Response> updateCertification(int id, Map<String, dynamic> data) =>
      dio.put('/api/v1/experts/certifications/$id/', data: data);

  Future<Response> deleteCertification(int id) =>
      dio.delete('/api/v1/experts/certifications/$id/');

  // HONOR
  Future<Response> addHonor(Map<String, dynamic> data) =>
      dio.post('/api/v1/experts/honors/', data: data);

  Future<Response> updateHonor(int id, Map<String, dynamic> data) =>
      dio.put('/api/v1/experts/honors/$id/', data: data);

  Future<Response> deleteHonor(int id) =>
      dio.delete('/api/v1/experts/honors/$id/');
}
