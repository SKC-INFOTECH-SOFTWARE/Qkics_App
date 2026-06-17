import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/home/post_card.dart';

class PostsTab extends StatelessWidget {
  final List<Post> posts;

  const PostsTab({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = context.watch<ApiProvider>();
    final currentUserId = api.currentUser?.id;

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No posts yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // If user not loaded yet, avoid wrong comparison
    if (currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12).copyWith(
        top: 12,
        bottom: 24,
      ),
      itemCount: posts.length,
      itemBuilder: (_, index) {
        return PostCard(post: posts[index], currentUserId: currentUserId);
      },
    );
  }
}
