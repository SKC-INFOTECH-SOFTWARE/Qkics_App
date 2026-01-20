// public_profile_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/profile/models/post_model.dart';

import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/profile/models/public_profile_model.dart';

class PublicProfileProvider extends ChangeNotifier {
  // ================= STATE =================
  bool isLoading = false;
  String? errorMessage;

  PublicProfileResponse? response;
  List<Post> posts = [];

  final Dio _dio = ApiProvider().dio;

  // ================= FETCH PUBLIC PROFILE =================
  Future<void> fetchPublicProfile(String username) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // ================= PROFILE =================
      final profileRes = await _dio.get('/api/v1/auth/profiles/$username/');

      response = PublicProfileResponse.fromJson(profileRes.data);

      // ================= POSTS =================
      final postsRes = await _dio.get(
        '/api/v1/community/posts/user/$username/',
      );
      print('🟢 Public posts raw: ${postsRes.data}');
      final data = postsRes.data;

      if (data is Map && data['results'] is List) {
        posts = (data['results'] as List).map((e) => Post.fromJson(e)).toList();
      } else {
        posts = [];
      }

      print('🟢 Public posts raw: ${postsRes.data}');
    } on DioException catch (e) {
      errorMessage = _parseDioError(e);
    } catch (e) {
      errorMessage = e.toString();
      print('🔴 Public profile error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // ================= ERROR PARSER =================
  String _parseDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;

      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }

      return 'Request failed (${e.response?.statusCode})';
    }

    return 'Network error. Please try again.';
  }

  // ================= RESET (OPTIONAL) =================
  void clear() {
    response = null;
    posts = [];
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}
