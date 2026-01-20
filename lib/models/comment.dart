// lib/models/comment.dart
class Comment {
  final int id;
  final Author author;
  final String content; // Still used as preview for backward compatibility
  final String? previewContent;
  final String? fullContent;
  final int? parent;
  int totalLikes;
  bool isLiked;
  final int depth;
  final DateTime createdAt;
  List<Comment> replies = [];
  int totalReplies;

  // THIS IS THE REAL ID YOUR BACKEND ACCEPTS
  final int rootCommentId; // ← Always the original top-level comment ID

  Comment({
    required this.id,
    required this.author,
    required this.content,
    this.previewContent,
    this.fullContent,
    this.parent,
    required this.totalLikes,
    required this.isLiked,
    required this.depth,
    required this.createdAt,
    required this.totalReplies,
    required this.rootCommentId,
    List<Comment>? replies,
  }) : replies = replies ?? [];

  factory Comment.fromJson(Map<String, dynamic> json) {
    final parentId = json['parent'] as int?;
    final commentId = json['id'] as int;

    return Comment(
      id: commentId,
      author: Author.fromJson(json['author']),
      content:
          json['content'] as String? ??
          json['preview_content'] as String? ??
          '',
      previewContent: json['preview_content'] as String?,
      fullContent: json['full_content'] as String?,
      parent: parentId,
      totalLikes: json['total_likes'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      depth: json['depth'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      totalReplies: json['total_replies'] ?? 0,
      rootCommentId: parentId == null ? commentId : parentId,
    );
  }
}

class Author {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String userTypeDisplay;
  final String? profilePicture; // ← NEW: Profile picture URL

  Author({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userTypeDisplay,
    this.profilePicture,
  });

  String get fullName {
    final name = "$firstName $lastName".trim();
    return name.isEmpty ? username : name;
  }

  // Helper: Get initial letter (fallback)
  String get initial => username.isNotEmpty ? username[0].toUpperCase() : "U";

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: (json['first_name'] as String?)?.trim() ?? '',
      lastName: (json['last_name'] as String?)?.trim() ?? '',
      userTypeDisplay: json['user_type_display'] as String? ?? 'User',
      profilePicture: json['profile_picture'] as String?, // ← Now parsed!
    );
  }
}
