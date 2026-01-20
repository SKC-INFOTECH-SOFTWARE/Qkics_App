// import 'package:q_kics/models/post.dart';

// class Post {
//   final int id;
//   final String? title;
//   final String content;

//   /// ✅ Author info (USED EVERYWHERE)
//   final PostAuthor author;

//   /// ✅ Tags with name
//   final List<PostTag> tags;

//   /// ✅ Image can be empty or null
//   final String? image;

//   /// ✅ Mutable (likes change in UI)
//   int totalLikes;
//   int totalComments;
//   bool isLiked;

//   final DateTime createdAt;

//   Post({
//     required this.id,
//     this.title,
//     required this.content,
//     required this.author,
//     required this.tags,
//     this.image,
//     required this.totalLikes,
//     required this.totalComments,
//     required this.isLiked,
//     required this.createdAt,
//   });

//   factory Post.fromJson(Map<String, dynamic> json) {
//     return Post(
//       id: json['id'],
//       title: json['title'],
//       content: json['content'] ?? '',

//       author: PostAuthor.fromJson(json['author']),

//       tags: (json['tags'] as List? ?? [])
//           .map((e) => PostTag.fromJson(e))
//           .toList(),

//       image: json['image']?.toString().trim().isEmpty == true
//           ? null
//           : json['image'],

//       totalLikes: json['total_likes'] ?? 0,
//       totalComments: json['total_comments'] ?? 0,
//       isLiked: json['is_liked'] ?? false,

//       createdAt: DateTime.parse(json['created_at']),
//     );
//   }
// }
