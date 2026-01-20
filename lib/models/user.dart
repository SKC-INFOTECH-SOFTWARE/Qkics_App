// lib/models/user.dart
import 'package:flutter/foundation.dart';
import 'package:q_kics/profile/utils/image_utils.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String userType; // normal, expert, entrepreneur, investor
  final String status;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profileImage;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.status,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.profileImage,
  });

  // SAFEST & MOST ROBUST fromJson EVER
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      username: (json['username'] as String?)?.trim() ?? 'unknown_user',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      firstName: (json['first_name'] as String?)?.trim() ?? '',
      lastName: (json['last_name'] as String?)?.trim() ?? '',
      userType:
          ((json['user_type'] as String?)?.toLowerCase().trim() ?? 'normal'),
      status: (json['status'] as String?)?.toLowerCase() ?? 'active',
      isVerified: json['is_verified'] == true || json['is_verified'] == 'true',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      profileImage: resolveImageUrl(
        _cleanUrl(json['profile_picture'] ?? json['profile_image']),
      ),
    );
  }

  // Helper: Safe date parsing
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  // Helper: Clean URL (remove null, empty, or broken urls)
  static String? _cleanUrl(dynamic url) {
    if (url == null) return null;
    final str = url.toString().trim();
    if (str.isEmpty || str == 'null' || str.contains('placeholder'))
      return null;
    return str;
  }

  // Perfect toJson for sending back to API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'status': status,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_picture': profileImage,
    };
  }

  // Beautiful full name
  String get fullName => '$firstName $lastName'.trim().isEmpty
      ? username
      : '$firstName $lastName'.trim();

  // Initials for avatar
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return f + l;
  }

  // For profile badge
  bool get isExpert => userType == 'expert';
  bool get isEntrepreneur => userType == 'entrepreneur';
  bool get isInvestor => userType == 'investor';
  bool get isNormal => userType == 'normal';

  String get userTypeDisplay {
    if (userType.isEmpty) return "User";
    return userType[0].toUpperCase() + userType.substring(1);
  }

  @override
  String toString() {
    return 'User(id: $id, name: $fullName, @$username, type: $userType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
