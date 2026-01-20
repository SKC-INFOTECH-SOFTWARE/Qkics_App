import 'package:q_kics/profile/utils/image_utils.dart';

class EntrepreneurProfile {
  final int id;
  final String username;
  final String? profilePicture;
  final String startupName;
  final String oneLiner;
  final String description;
  final String website;
  final String industry;
  final String location;
  final String fundingStage;
  final String applicationStatus;

  EntrepreneurProfile({
    required this.id,
    required this.username,
    this.profilePicture,
    required this.startupName,
    required this.oneLiner,
    required this.description,
    required this.website,
    required this.industry,
    required this.location,
    required this.fundingStage,
    required this.applicationStatus,
  });

  factory EntrepreneurProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final String? rawImage =
        json['profile_picture'] ?? user?['profile_picture'];
    return EntrepreneurProfile(
      id: json['id'],
      username: user?['username'] ?? '',
      profilePicture: resolveImageUrl(rawImage),
      startupName: json['startup_name'] ?? '',
      oneLiner: json['one_liner'] ?? '',
      description: json['description'] ?? '',
      website: json['website'] ?? '',
      industry: json['industry'] ?? '',
      location: json['location'] ?? '',
      fundingStage: json['funding_stage'] ?? '',
      applicationStatus: json['application_status'] ?? 'pending',
    );
  }
}
