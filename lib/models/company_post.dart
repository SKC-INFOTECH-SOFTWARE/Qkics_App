import 'package:q_kics/models/post.dart';

class CompanyPostCompany {
  final String id;
  final String name;
  final String slug;
  final String? logo;

  CompanyPostCompany({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
  });

  factory CompanyPostCompany.fromJson(Map<String, dynamic> json) {
    return CompanyPostCompany(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logo: json['logo'],
    );
  }
}

class CompanyPost {
  final String id;
  final CompanyPostCompany company;
  final String author;
  final String title;
  final String content;
  final List<PostMedia> media;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  CompanyPost({
    required this.id,
    required this.company,
    required this.author,
    required this.title,
    required this.content,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory CompanyPost.fromJson(Map<String, dynamic> json) {
    return CompanyPost(
      id: json['id'] ?? '',
      company: CompanyPostCompany.fromJson(json['company'] ?? {}),
      author: json['author'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => PostMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }
}
