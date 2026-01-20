import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/home/post_detail_page.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/models/tag.dart';
import 'package:shimmer/shimmer.dart';
import 'package:q_kics/home/comment_sheet.dart';
import 'package:q_kics/home/create_post_page.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int currentUserId;

  const PostCard({
    super.key,
    required this.post,
    this.onEdit,
    this.onDelete,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTitle = post.title?.trim().isNotEmpty ?? false;

    final bool isMyPost = post.author.id == currentUserId;

    return Card(
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= AUTHOR HEADER =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  backgroundImage:
                      post.author.profileImage != null &&
                          post.author.profileImage!.trim().isNotEmpty
                      ? CachedNetworkImageProvider(post.author.profileImage!)
                      : null,
                  child:
                      (post.author.profileImage == null ||
                          post.author.profileImage!.trim().isEmpty)
                      ? Text(
                          post.author.username[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // Name + Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _timeAgo(post.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Menu (only own post)
                if (isMyPost) _moreMenu(context),
              ],
            ),
          ),

          // ================= TITLE =================
          if (hasTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                post.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          // ================= CONTENT =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(post.content, style: theme.textTheme.bodyMedium),
          ),

          // ================= TAGS =================
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: post.tags.map<Widget>((PostTag tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${tag.name}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ================= IMAGE =================
          if (post.image != null && post.image!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailPage(
                      post: post,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'post_image_${post.id}_${post.image.hashCode}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: post.image!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(height: 280),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 280,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ================= FOOTER =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                _iconText(
                  context,
                  Icons.favorite_border,
                  post.totalLikes.toString(),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentSheet(postId: post.id),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.comment_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${post.totalComments} Answer${post.totalComments == 1 ? '' : 's'}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MORE MENU =================
  Widget _moreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'edit') {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => CreatePostPage(postToEdit: post)),
          );
          if (updated == true && context.mounted) {
            onEdit?.call();
          }
        }

        if (value == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Delete Post?"),
              content: const Text("This action cannot be undone."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            onDelete?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Post deleted"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 12),
              Text("Edit Post"),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 12),
              Text("Delete Post", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  // ================= ICON + TEXT =================
  Widget _iconText(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.iconTheme.color),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }

  // ================= TIME AGO =================
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
