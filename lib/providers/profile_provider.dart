// profile_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ← NEW
import 'package:q_kics/models/post.dart';
import 'package:q_kics/profile/models/post_model.dart';
import 'package:q_kics/profile/models/user_profile_model.dart';
import 'package:q_kics/profile/services/profile_api_service.dart';
import 'package:q_kics/profile/models/profile_type.dart';
import 'package:q_kics/providers/api_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileApiService api;
  final ApiProvider apiProvider;

  ProfileProvider(this.api, this.apiProvider);

  UserProfile? profile;
  List<Post> posts = [];
  bool loadingProfile = false;
  bool loadingPosts = false;

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

  ProfileType get profileType => ProfileType.fromString(profile?.userType);

  // ================= LOAD PROFILE (ONCE) =================
  Future<void> loadProfile({bool force = false}) async {
    if (profile != null && !force) return;
    loadingProfile = true;
    notifyListeners();

    try {
      profile = await api.fetchMyProfile();
      await loadMyPosts();
    } catch (e) {
      debugPrint("Profile load failed (already handled globally): $e");
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }

  // ================= LOAD POSTS (SEPARATE) =================
  Future<void> loadMyPosts({bool force = false}) async {
    if (profile == null) return;
    if (posts.isNotEmpty && !force) return;

    loadingPosts = true;
    notifyListeners();

    try {
      posts = await api.fetchUserPosts(profile!.username);
    } catch (e) {
      debugPrint("User posts load failed (already handled globally): $e");
    } finally {
      loadingPosts = false;
      notifyListeners();
    }
  }

  // ================= UPDATE PROFILE =================
  Future<void> updateMyProfile({
    required String firstName,
    required String lastName,
    required String phone,
    File? image,
  }) async {
    loadingProfile = true;
    notifyListeners();

    final String? oldImageUrl = profile?.profilePicture;

    try {
      final data = await api.updateMyProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: image,
      );

      profile = UserProfile.fromJson(data);

      await apiProvider.getCurrentUser();

      if (oldImageUrl != null &&
          oldImageUrl.isNotEmpty &&
          oldImageUrl != profile?.profilePicture) {
        await CachedNetworkImage.evictFromCache(oldImageUrl);
      }
      notifyListeners();
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }
}
