import 'package:q_kics/models/post.dart';
import 'package:q_kics/profile/utils/image_utils.dart';

List<PostMedia> _parseCompanyPostMedia(Map<String, dynamic> json) {
  final rawMedia =
      json['media'] ?? json['uploaded_files'] ?? json['uploaded_files[]'];
  if (rawMedia is! List) return [];

  return rawMedia
      .map<PostMedia?>((item) {
        if (item is! Map) return null;
        final map = Map<String, dynamic>.from(item);
        return PostMedia.fromJson({
          'id': _coerceMediaId(map['id']),
          'media_type': map['media_type'] ?? _inferMediaType(map['file']),
          'file': map['file'] ?? '',
          'order': map['order'] ?? 0,
        });
      })
      .whereType<PostMedia>()
      .where((media) => media.file.trim().isNotEmpty)
      .toList();
}

int _coerceMediaId(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? value.hashCode;
  return 0;
}

String _inferMediaType(dynamic fileValue) {
  final file = (fileValue ?? '').toString().toLowerCase();
  if (file.endsWith('.mp4') ||
      file.endsWith('.mov') ||
      file.endsWith('.avi') ||
      file.endsWith('.mkv') ||
      file.endsWith('.webm')) {
    return 'video';
  }
  return 'image';
}

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
      logo: resolveImageUrl(json['logo']),
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
    final rawAuthor = json['author'];
    final author = switch (rawAuthor) {
      String value => value,
      Map<String, dynamic> value =>
        (value['username'] ?? value['full_name'] ?? value['name'] ?? '')
            .toString(),
      Map value => (value['username'] ?? value['full_name'] ?? value['name'] ?? '')
          .toString(),
      _ => '',
    };

    return CompanyPost(
      id: (json['id'] ?? '').toString(),
      company: CompanyPostCompany.fromJson(json['company'] ?? {}),
      author: author,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      media: _parseCompanyPostMedia(json),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? true,
    );
  }
}
