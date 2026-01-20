// public_profile_model.dart

class PublicProfileResponse {
  final String role;
  final dynamic profile;

  PublicProfileResponse({required this.role, required this.profile});

  factory PublicProfileResponse.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String;
    final data = json['profile'] as Map<String, dynamic>;

    switch (role) {
      case 'user':
        return PublicProfileResponse(
          role: role,
          profile: PublicUserProfile.fromJson(data),
        );
      case 'entrepreneur':
        return PublicProfileResponse(
          role: role,
          profile: PublicEntrepreneurProfile.fromJson(data),
        );
      case 'expert':
        return PublicProfileResponse(
          role: role,
          profile: PublicExpertProfile.fromJson(data),
        );
      case 'investor':
        return PublicProfileResponse(
          role: role,
          profile: PublicInvestorProfile.fromJson(data),
        );
      default:
        throw Exception('Unsupported role: $role');
    }
  }
}

/// ================= NORMAL USER =================
class PublicUserProfile {
  final int id; // exists in API
  final String uuid;
  final String username;
  final String firstName;
  final String lastName;
  final String userType;
  final String? profilePicture;

  PublicUserProfile({
    required this.id,
    required this.uuid,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.profilePicture,
  });

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    return PublicUserProfile(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      userType: json['user_type'] as String,
      profilePicture: json['profile_picture'] as String?,
    );
  }
}

/// ================= SHARED USER =================
class PublicUser {
  final int id;
  final String uuid;
  final String username;
  final String firstName;
  final String lastName;
  final String userType;
  final String? profilePicture;

  PublicUser({
    required this.id,
    required this.uuid,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.profilePicture,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      userType: json['user_type'] as String,
      profilePicture: json['profile_picture'] as String?,
    );
  }
}

/// ================= ENTREPRENEUR =================
class PublicEntrepreneurProfile {
  final int id;
  final PublicUser user;
  final bool? isOwner; // 🔑 NULLABLE
  final String startupName;
  final String oneLiner;
  final String description;
  final String website;
  final String logo;
  final String industry;
  final String location;
  final String fundingStage;
  final bool verifiedByAdmin;

  PublicEntrepreneurProfile({
    required this.id,
    required this.user,
    this.isOwner,
    required this.startupName,
    required this.oneLiner,
    required this.description,
    required this.website,
    required this.logo,
    required this.industry,
    required this.location,
    required this.fundingStage,
    required this.verifiedByAdmin,
  });

  factory PublicEntrepreneurProfile.fromJson(Map<String, dynamic> json) {
    return PublicEntrepreneurProfile(
      id: json['id'] ?? 0,
      user: PublicUser.fromJson(json['user']),
      isOwner: json['is_owner'] as bool?,
      startupName: json['startup_name'] ?? '',
      oneLiner: json['one_liner'] ?? '',
      description: json['description'] ?? '',
      website: json['website'] ?? '',
      logo: json['logo'] ?? '',
      industry: json['industry'] ?? '',
      location: json['location'] ?? '',
      fundingStage: json['funding_stage'] ?? '',
      verifiedByAdmin: json['verified_by_admin'] ?? false,
    );
  }
}

/// ================= EXPERT =================
class PublicExpertProfile {
  final int id;
  final PublicUser user;

  final String firstName;
  final String lastName;
  final String headline;
  final String? profilePicture;

  final String primaryExpertise;
  final String? otherExpertise;
  final String? hourlyRate;
  final bool isAvailable;
  final bool verifiedByAdmin;

  // ✅ PORTFOLIO
  final List<Map<String, dynamic>> experiences;
  final List<Map<String, dynamic>> educations;
  final List<Map<String, dynamic>> certifications;
  final List<Map<String, dynamic>> honorsAwards;

  PublicExpertProfile({
    required this.id,
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.headline,
    this.profilePicture,
    required this.primaryExpertise,
    this.otherExpertise,
    this.hourlyRate,
    required this.isAvailable,
    required this.verifiedByAdmin,
    required this.experiences,
    required this.educations,
    required this.certifications,
    required this.honorsAwards,
  });

  factory PublicExpertProfile.fromJson(Map<String, dynamic> json) {
    return PublicExpertProfile(
      id: json['id'],
      user: PublicUser.fromJson(json['user']),
      firstName: json['first_name'],
      lastName: json['last_name'],
      headline: json['headline'],
      profilePicture: json['profile_picture'],
      primaryExpertise: json['primary_expertise'],
      otherExpertise: json['other_expertise'],
      hourlyRate: json['hourly_rate'],
      isAvailable: json['is_available'],
      verifiedByAdmin: json['verified_by_admin'],

      // ✅ SAFE LIST PARSING
      experiences: List<Map<String, dynamic>>.from(json['experiences'] ?? []),
      educations: List<Map<String, dynamic>>.from(json['educations'] ?? []),
      certifications: List<Map<String, dynamic>>.from(
        json['certifications'] ?? [],
      ),
      honorsAwards: List<Map<String, dynamic>>.from(
        json['honors_awards'] ?? [],
      ),
    );
  }
}

/// ================= INVESTOR =================
class PublicInvestorProfile {
  final int id;
  final PublicUser user;
  final String displayName;
  final String oneLiner;
  final String investmentThesis;
  final List<PublicInvestorOption> focusIndustries;
  final List<PublicInvestorOption> preferredStages;
  final String checkSizeMin;
  final String checkSizeMax;
  final String location;
  final String? websiteUrl;
  final String? linkedinUrl;
  final String? twitterUrl;
  final String investorType;
  final String investorTypeDisplay;
  final bool verifiedByAdmin;

  PublicInvestorProfile({
    required this.id,
    required this.user,
    required this.displayName,
    required this.oneLiner,
    required this.investmentThesis,
    required this.focusIndustries,
    required this.preferredStages,
    required this.checkSizeMin,
    required this.checkSizeMax,
    required this.location,
    this.websiteUrl,
    this.linkedinUrl,
    this.twitterUrl,
    required this.investorType,
    required this.investorTypeDisplay,
    required this.verifiedByAdmin,
  });

  factory PublicInvestorProfile.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return PublicInvestorProfile(
      id: json['id'] ?? 0,
      user: PublicUser.fromJson(json['user']),
      displayName: json['display_name'] ?? '',
      oneLiner: json['one_liner'] ?? '',
      investmentThesis: json['investment_thesis'] ?? '',
      focusIndustries: (json['focus_industries'] as List? ?? [])
          .map((e) => PublicInvestorOption.fromJson(e))
          .toList(),
      preferredStages: (json['preferred_stages'] as List? ?? [])
          .map((e) => PublicInvestorOption.fromJson(e))
          .toList(),
      checkSizeMin: json['check_size_min']?.toString() ?? '0',
      checkSizeMax: json['check_size_max']?.toString() ?? '0',
      location: json['location'] ?? userJson?['location'] ?? '',
      websiteUrl: json['website_url'],
      linkedinUrl: json['linkedin_url'],
      twitterUrl: json['twitter_url'],
      investorType: json['investor_type'] ?? '',
      investorTypeDisplay:
          (json['investor_type_display']?.toString().isNotEmpty == true)
          ? json['investor_type_display']
          : _getInvestorTypeDisplay(json['investor_type'] ?? ''),
      verifiedByAdmin: json['verified_by_admin'] ?? false,
    );
  }

  static String _getInvestorTypeDisplay(String type) {
    switch (type.toLowerCase()) {
      case 'angel':
        return 'Angel Investor';
      case 'vc':
        return 'VC Firm';
      case 'family_office':
        return 'Family Office';
      case 'corporate':
        return 'Corporate VC';
      default:
        return type.isNotEmpty
            ? type[0].toUpperCase() + type.substring(1)
            : 'Investor';
    }
  }
}

class PublicInvestorOption {
  final int id;
  final String name;

  PublicInvestorOption({required this.id, required this.name});

  factory PublicInvestorOption.fromJson(Map<String, dynamic> json) {
    return PublicInvestorOption(id: json['id'], name: json['name'] ?? '');
  }
}
