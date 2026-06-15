import 'package:q_kics/models/user.dart';

class CompanyMember {
  final String id;
  final User? user;
  final String? userString; // Fallback for when API returns string instead of user object
  final String role;
  final DateTime joinedAt;

  CompanyMember({
    required this.id,
    this.user,
    this.userString,
    required this.role,
    required this.joinedAt,
  });

  factory CompanyMember.fromJson(Map<String, dynamic> json) {
    User? parsedUser;
    String? parsedUserString;

    if (json['user'] != null) {
      if (json['user'] is Map<String, dynamic>) {
        parsedUser = User.fromJson(json['user']);
      } else if (json['user'] is String) {
        parsedUserString = json['user'];
      }
    }

    return CompanyMember(
      id: json['id'] ?? '',
      user: parsedUser,
      userString: parsedUserString,
      role: json['role'] ?? 'member',
      joinedAt: DateTime.tryParse(json['joined_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson() ?? userString,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class Company {
  final String id;
  final String name;
  final String slug;
  final String? logo;
  final String? coverImage;
  final String description;
  final String industry;
  final String website;
  final String location;
  final String owner;
  final String status;
  final List<CompanyMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.coverImage,
    required this.description,
    required this.industry,
    required this.website,
    required this.location,
    required this.owner,
    required this.status,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logo: json['logo'],
      coverImage: json['cover_image'] ?? json['cover_picture'],
      description: json['description'] ?? '',
      industry: json['industry'] ?? '',
      website: json['website'] ?? '',
      location: json['location'] ?? '',
      owner: json['owner'] ?? '',
      status: json['status'] ?? 'pending',
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => CompanyMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
