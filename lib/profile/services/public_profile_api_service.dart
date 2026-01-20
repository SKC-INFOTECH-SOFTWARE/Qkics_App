// lib/profile/services/public_profile_api_service.dart
import 'package:dio/dio.dart';

class PublicProfileApiService {
  final Dio dio;
  PublicProfileApiService(this.dio);

  Future<Map<String, dynamic>> getPublicProfile(String username) async {
    final res = await dio.get('/api/v1/auth/profiles/$username/');
    return res.data;
  }
}
