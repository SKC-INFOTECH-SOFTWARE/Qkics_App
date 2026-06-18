// lib/models/post.dart
import 'package:q_kics/profile/utils/image_utils.dart';

class PostAuthor {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String userType;
  final String userTypeDisplay;
  final String profileImage;

  PostAuthor({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.userTypeDisplay,
    required this.profileImage,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'],
      username: json['username'] ?? 'Anonymous',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      userType: json['user_type'] ?? 'normal',
      userTypeDisplay: json['user_type_display'] ?? 'User',
      profileImage: json['profile_picture'] ?? '',
    );
  }

  String get fullName {
    final name = "${firstName.trim()} ${lastName.trim()}".trim();
    return name.isEmpty ? username : name;
  }

  PostAuthor copyWith({String? profileImage}) {
    return PostAuthor(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      userType: userType,
      userTypeDisplay: userTypeDisplay,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class PostTag {
  final int id;
  final String name;
  final String slug;

  PostTag({required this.id, required this.name, required this.slug});

  factory PostTag.fromJson(Map<String, dynamic> json) {
    return PostTag(id: json['id'], name: json['name'], slug: json['slug']);
  }
}

class PostMedia {
  final int id;
  final String mediaType;
  final String file;
  final int order;

  PostMedia({
    required this.id,
    required this.mediaType,
    required this.file,
    required this.order,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    final rawFile = (json['file'] ?? '').toString();
    return PostMedia(
      id: json['id'],
      mediaType: json['media_type'] ?? 'image',
      file: resolveImageUrl(rawFile) ?? rawFile,
      order: json['order'] ?? 0,
    );
  }

  bool get isVideo {
    if (mediaType == 'video') return true;
    final lowerFile = file.toLowerCase();
    return lowerFile.endsWith('.mp4') ||
        lowerFile.endsWith('.mov') ||
        lowerFile.endsWith('.avi') ||
        lowerFile.endsWith('.mkv') ||
        lowerFile.endsWith('.webm');
  }
}

class Post {
  final int id;
  final PostAuthor author;
  final String? title;
  final String content; // Still used as preview for backward compatibility
  final String? previewContent;
  final String? fullContent;
  final String? image;
  final List<PostMedia> media;
  final List<PostTag> tags;
  final bool knowledgeHub;

  int totalLikes;
  int totalComments;
  bool isLiked;

  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.author,
    this.title,
    required this.content,
    this.previewContent,
    this.fullContent,
    this.image,
    required this.media,
    required this.tags,
    required this.knowledgeHub,
    required this.totalLikes,
    required this.totalComments,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  Post copyWith({PostAuthor? author}) {
    return Post(
      id: id,
      author: author ?? this.author,
      title: title,
      content: content,
      previewContent: previewContent,
      fullContent: fullContent,
      image: image,
      media: media,
      tags: tags,
      knowledgeHub: knowledgeHub,
      totalLikes: totalLikes,
      totalComments: totalComments,
      isLiked: isLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: PostAuthor.fromJson(json['author']),
      title: json['title'],
      content: json['content'] ?? json['preview_content'] ?? '',
      previewContent: json['preview_content'],
      fullContent: json['full_content'],
      image: (() {
        // First try to get from the new media objects list
        final mediaList = json['media'];
        if (mediaList is List && mediaList.isNotEmpty) {
          final first = mediaList.first;
          if (first is Map) {
            final url =
                (first['file'] ?? first['media'] ?? first['url']) as String?;
            if (url != null && url.trim().isNotEmpty) return url;
          }
        }
        // Fallback to legacy string or other media handling
        final media = json['media'];
        if (media == null) return null;
        if (media is String) {
          final trimmed = media.trim();
          return trimmed.isEmpty ? null : media;
        }
        if (media is List) {
          for (final item in media) {
            if (item is String) {
              final trimmed = item.trim();
              if (trimmed.isNotEmpty) return item;
            } else if (item is Map) {
              final url =
                  (item['url'] ?? item['media'] ?? item['file']) as String?;
              if (url != null && url.trim().isNotEmpty) return url;
            }
          }
          return null;
        }
        if (media is Map) {
          final url =
              (media['url'] ?? media['media'] ?? media['file']) as String?;
          if (url != null && url.trim().isNotEmpty) return url;
        }
        return null;
      })(),
      media: (json['media'] is List)
          ? (json['media'] as List)
                .map((e) => PostMedia.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      tags: (json['tags'] as List? ?? [])
          .map((e) => PostTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      knowledgeHub: json['knowledge_hub'] ?? false,
      totalLikes: json['total_likes'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
    );
  }
}
