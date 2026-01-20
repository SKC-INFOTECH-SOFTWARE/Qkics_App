class ExpertModel {
  final String expertUuid; // 🔑 THIS is used for booking
  final String name;
  final String headline;
  final String primaryExpertise;
  final String? profilePicture;
  final double hourlyRate;
  final bool isAvailable;
  final bool verified;

  ExpertModel({
    required this.expertUuid,
    required this.name,
    required this.headline,
    required this.primaryExpertise,
    required this.profilePicture,
    required this.hourlyRate,
    required this.isAvailable,
    required this.verified,
  });

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};

    return ExpertModel(
      expertUuid: json['user']['uuid'],
      name: "${json['first_name']} ${json['last_name']}",
      headline: json['headline'] ?? '',
      primaryExpertise: json['primary_expertise'] ?? '',
      profilePicture: user['profile_picture'],
      hourlyRate: double.tryParse(json['hourly_rate'].toString()) ?? 0,
      isAvailable: json['is_available'] ?? false,
      verified: json['verified_by_admin'] ?? false,
    );
  }
}
