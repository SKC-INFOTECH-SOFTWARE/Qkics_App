// public_profile_mapper.dart

import 'package:q_kics/profile/models/user_profile_model.dart';
import 'package:q_kics/profile/models/public_profile_model.dart';
import 'package:q_kics/profile/utils/image_utils.dart';

extension PublicProfileMapper on PublicProfileResponse {
  UserProfile toUserProfile() {
    // ================= NORMAL USER =================
    if (profile is PublicUserProfile) {
      final p = profile as PublicUserProfile;

      return UserProfile(
        id: null,
        username: p.username,
        firstName: p.firstName,
        lastName: p.lastName,
        userType: 'normal',
        profilePicture: resolveImageUrl(p.profilePicture),
        email: '',
        phone: '',
        uuid: p.uuid,
      );
    }

    // ================= EXPERT =================
    if (profile is PublicExpertProfile) {
      final p = profile as PublicExpertProfile;

      // 🔑 IMPORTANT: expert avatar comes from USER
      final String? image = p.profilePicture ?? p.user.profilePicture;

      return UserProfile(
        id: p.id,
        username: p.user.username,
        firstName: p.firstName,
        lastName: p.lastName,
        userType: 'expert',
        profilePicture: resolveImageUrl(image),
        email: '',
        phone: '',
        uuid: '${p.user.uuid}',
      );
    }

    // ================= ENTREPRENEUR =================
    if (profile is PublicEntrepreneurProfile) {
      final p = profile as PublicEntrepreneurProfile;

      // 🔑 Priority:
      // 1. user.profilePicture
      // 2. startup logo
      final String? image = p.user.profilePicture ?? p.logo;

      return UserProfile(
        id: p.user.id,
        username: p.user.username,
        firstName: p.user.firstName,
        lastName: p.user.lastName,
        userType: 'entrepreneur',
        profilePicture: resolveImageUrl(image),
        email: '',
        phone: '',
        uuid: '${p.user.uuid}',
      );
    }

    // ================= INVESTOR =================
    if (profile is PublicInvestorProfile) {
      final p = profile as PublicInvestorProfile;

      return UserProfile(
        id: p.user.id,
        username: p.user.username,
        firstName: p.user.firstName,
        lastName: p.user.lastName,
        userType: 'investor',
        profilePicture: resolveImageUrl(p.user.profilePicture),
        email: '',
        phone: '',
        uuid: '${p.user.uuid}',
      );
    }

    throw Exception('Unsupported public profile type: ${profile.runtimeType}');
  }
}
