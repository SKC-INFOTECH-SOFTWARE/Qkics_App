import 'package:q_kics/profile/utils/image_utils.dart';

class ExpertProfile {
  final int id;
  final String uuid;
  final String username;
  final String? profilePicture;
  final String firstName;
  final String lastName;
  final String headline;
  final bool verified;
  final String applicationStatus;
  final String? adminReviewNote;
  final String primaryExpertise;
  final String? otherExpertise;
  final int hourlyRate;
  final bool isAvailable;
  final List<Map<String, dynamic>> experiences;
  final List<Map<String, dynamic>> educations;
  final List<Map<String, dynamic>> certifications;
  final List<Map<String, dynamic>> honors;

  ExpertProfile({
    required this.id,
    required this.uuid,
    required this.username,
    this.profilePicture,
    required this.firstName,
    required this.lastName,
    required this.headline,
    required this.verified,
    required this.applicationStatus,
    this.adminReviewNote,
    required this.primaryExpertise,
    this.otherExpertise,
    required this.hourlyRate,
    required this.isAvailable,
    required this.experiences,
    required this.educations,
    required this.certifications,
    required this.honors,
  });

  static int _parseHourlyRate(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.round() ?? 0;
    }
    return 0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  ExpertProfile copyWith({
    String? applicationStatus,
    String? adminReviewNote,
    bool? verified,
    String? profilePicture,
  }) {
    return ExpertProfile(
      id: id,
      uuid: uuid,
      username: username,
      profilePicture: profilePicture ?? this.profilePicture,
      firstName: firstName,
      lastName: lastName,
      headline: headline,
      primaryExpertise: primaryExpertise,
      otherExpertise: otherExpertise,
      hourlyRate: hourlyRate,
      isAvailable: isAvailable,
      verified: verified ?? this.verified,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      adminReviewNote: adminReviewNote ?? this.adminReviewNote,
      experiences: experiences,
      educations: educations,
      certifications: certifications,
      honors: honors,
    );
  }

  factory ExpertProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final String? rawImage =
        json['profile_picture'] ?? user?['profile_picture'];
    return ExpertProfile(
      id: _parseInt(json['id']),
      uuid: user?['uuid'] ?? '',
      username: user?['username'] ?? '',
      profilePicture: resolveImageUrl(rawImage),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      headline: json['headline'] ?? '',
      verified: json['verified_by_admin'] ?? false,
      applicationStatus: json['application_status'] ?? 'pending',
      adminReviewNote: json['admin_review_note'],
      primaryExpertise: json['primary_expertise'] ?? '',
      otherExpertise: json['other_expertise'],
      hourlyRate: _parseHourlyRate(json['hourly_rate']),
      isAvailable: json['is_available'] ?? true,
      experiences: List<Map<String, dynamic>>.from(json['experiences'] ?? []),
      educations: List<Map<String, dynamic>>.from(json['educations'] ?? []),
      certifications: List<Map<String, dynamic>>.from(
        json['certifications'] ?? [],
      ),
      honors: List<Map<String, dynamic>>.from(json['honors_awards'] ?? []),
    );
  }
}
