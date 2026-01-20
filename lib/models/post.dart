// lib/models/post.dart

class PostAuthor {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String userTypeDisplay;
  final String profileImage;

  PostAuthor({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userTypeDisplay,
    required this.profileImage,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'],
      username: json['username'] ?? 'Anonymous',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      userTypeDisplay: json['user_type_display'] ?? 'User',
      profileImage: json['profile_picture'] ?? '',
    );
  }

  String get fullName {
    final name = "${firstName.trim()} ${lastName.trim()}".trim();
    return name.isEmpty ? username : name;
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

class Post {
  final int id;
  final PostAuthor author;
  final String? title;
  final String content; // Still used as preview for backward compatibility
  final String? previewContent;
  final String? fullContent;
  final String? image;
  final List<PostTag> tags;

  int totalLikes;
  int totalComments;
  bool isLiked;

  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    this.title,
    required this.content,
    this.previewContent,
    this.fullContent,
    this.image,
    required this.tags,
    required this.totalLikes,
    required this.totalComments,
    required this.isLiked,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      author: PostAuthor.fromJson(json['author']),
      title: json['title'],
      content: json['content'] ?? json['preview_content'] ?? '',
      previewContent: json['preview_content'],
      fullContent: json['full_content'],
      image: (json['image'] as String?)?.trim().isEmpty == true
          ? null
          : json['image'],
      tags: (json['tags'] as List? ?? [])
          .map((e) => PostTag.fromJson(e))
          .toList(),
      totalLikes: json['total_likes'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
