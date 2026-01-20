class UserProfile {
  final int? id;
  final String uuid;
  final String username;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String userType;
  final String? profilePicture;

  UserProfile({
    this.id,
    required this.uuid,
    required this.username,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.profilePicture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] is int ? json['id'] : null,
      uuid: json['uuid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      userType: json['user_type'] ?? 'normal',
      profilePicture: json['profile_picture'],
    );
  }

  /// 👉 Display name logic
  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : username;
  }

  /// 👉 Initial for avatar fallback
  String get initial {
    if (displayName.isNotEmpty) {
      return displayName[0].toUpperCase();
    }
    return '?';
  }
}
