import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/profile/models/post_model.dart';
import 'package:q_kics/profile/models/user_profile_model.dart';

class ProfileApiService {
  final Dio dio;

  ProfileApiService(this.dio);
  Future<UserProfile> fetchMyProfile() async {
    final response =  await dio.get('/api/v1/auth/me/');
    return UserProfile.fromJson(response.data);
  }

  Future<List<Post>> fetchUserPosts(String username) async {
    final response = await dio.get('/api/v1/community/posts/user/$username/');

    return (response.data['results'] as List)
        .map((e) => Post.fromJson(e))
        .toList();
  }

  //updateMyProfile

  // ✅ PATCH — update profile
  Future<Map<String, dynamic>> updateMyProfile({
    required String firstName,
    required String lastName,
    required String phone,
    File? profileImage,
  }) async {
    final formData = FormData.fromMap({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      if (profileImage != null)
        'profile_picture': await MultipartFile.fromFile(
          profileImage.path,
          filename: profileImage.path.split('/').last,
        ),
    });

    // 🔥 DEBUG EVERYTHING
    debugPrint('📤 UPDATE PROFILE FORM DATA');
    for (final f in formData.fields) {
      debugPrint('FIELD → ${f.key}: ${f.value}');
    }
    for (final f in formData.files) {
      debugPrint('FILE → ${f.key}: ${f.value.filename}');
    }

    final res = await dio.patch(
      '/api/v1/auth/me/update/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    debugPrint('📥 UPDATE PROFILE RESPONSE → ${res.data}');
    return res.data;
  }

  Future<Map<String, dynamic>> fetchPublicProfile(String username) async {
    final res = await dio.get('/api/v1/auth/profiles/$username/');
    return res.data as Map<String, dynamic>;
  }
}
