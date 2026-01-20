import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'post_card.dart';

class PostsTab extends StatelessWidget {
  final List<Post> posts;

  const PostsTab({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    print('🟡 PostsTab received posts: ${posts.length}');

    final api = context.watch<ApiProvider>();
    final currentUserId = api.currentUser?.id;

    if (posts.isEmpty) {
      return const Center(
        child: Text(
          'No posts yet',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey,
          ),
        ),
      );
    }

    // If user not loaded yet, avoid wrong comparison
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      itemCount: posts.length,
      itemBuilder: (_, index) {
        return PostCard(
          post: posts[index],
          currentUserId: currentUserId, // ✅ REAL USER ID
        );
      },
    );
  }
}
