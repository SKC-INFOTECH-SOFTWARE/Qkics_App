import 'package:q_kics/profile/utils/image_utils.dart';

class InvestorProfile {
  final int id;
  final String username;
  final String? profilePicture;
  final String displayName;
  final String oneLiner;
  final String investmentThesis;
  final List<InvestorOption> focusIndustries;
  final List<InvestorOption> preferredStages;
  final double checkSizeMin;
  final double checkSizeMax;
  final String location;
  final String? websiteUrl;
  final String? linkedinUrl;
  final String? twitterUrl;
  final String investorType;
  final String investorTypeDisplay;
  final bool verifiedByAdmin;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvestorProfile({
    required this.id,
    required this.username,
    this.profilePicture,
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
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory InvestorProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    // Prioritize top-level profile_picture (usually resolved)
    // but fallback to user's profile_picture
    final String? rawImage =
        json['profile_picture'] ?? user?['profile_picture'];

    final String? itd = json['investor_type_display']?.toString();
    final String it = json['investor_type']?.toString() ?? '';

    return InvestorProfile(
      id: json['id'] ?? 0,
      username: user?['username'] ?? '',
      profilePicture: resolveImageUrl(rawImage),
      displayName: json['display_name'] ?? '',
      oneLiner: json['one_liner'] ?? '',
      investmentThesis: json['investment_thesis'] ?? '',
      focusIndustries:
          (json['focus_industries'] as List?)
              ?.map((e) => InvestorOption.fromJson(e))
              .toList() ??
          [],
      preferredStages:
          (json['preferred_stages'] as List?)
              ?.map((e) => InvestorOption.fromJson(e))
              .toList() ??
          [],
      checkSizeMin:
          double.tryParse(json['check_size_min']?.toString() ?? '0') ?? 0,
      checkSizeMax:
          double.tryParse(json['check_size_max']?.toString() ?? '0') ?? 0,
      location:
          json['location']?.toString() ?? user?['location']?.toString() ?? '',
      websiteUrl: json['website_url'],
      linkedinUrl: json['linkedin_url'],
      twitterUrl: json['twitter_url'],
      investorType: it,
      investorTypeDisplay: (itd != null && itd.isNotEmpty)
          ? itd
          : _getInvestorTypeDisplay(it),
      verifiedByAdmin: json['verified_by_admin'] ?? false,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
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

class InvestorOption {
  final int id;
  final String name;

  InvestorOption({required this.id, required this.name});

  factory InvestorOption.fromJson(Map<String, dynamic> json) {
    return InvestorOption(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}
