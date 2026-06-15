import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/home/post_detail_page.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:q_kics/home/comment_sheet.dart';
import 'package:q_kics/home/create_post_page.dart';
import 'package:q_kics/widgets/video_player_widget.dart';

class PostCard extends StatefulWidget {
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
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  int _currentPage = 0;
  bool _showHeart = false;
  late AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.post.isLiked) {
      _toggleLike();
    }
    setState(() => _showHeart = true);
    _heartController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showHeart = false);
      });
    });
  }

  void _toggleLike() async {
    final api = context.read<ApiProvider>();
    setState(() {
      widget.post.isLiked = !widget.post.isLiked;
      widget.post.totalLikes = widget.post.isLiked
          ? widget.post.totalLikes + 1
          : widget.post.totalLikes - 1;
    });
    await api.togglePostLike(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUserId = widget.currentUserId;
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

          // ================= MEDIA (IMGS/VIDEOS) =================
          if (post.media.isNotEmpty) _buildMediaCarousel(context),

          // ================= FOOTER =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        widget.post.isLiked
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        color: widget.post.isLiked
                            ? Colors.red
                            : theme.iconTheme.color,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.post.totalLikes > 0
                            ? '${widget.post.totalLikes}'
                            : 'Like',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
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
                        "${post.totalComments} Comment${post.totalComments == 1 ? '' : 's'}",
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
            MaterialPageRoute(
              builder: (_) => CreatePostPage(postToEdit: widget.post),
            ),
          );
          if (updated == true && context.mounted) {
            widget.onEdit?.call();
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
            final api = context.read<ApiProvider>();

            final success = await api.deletePost(widget.post.id);

            if (success && context.mounted) {
              // Remove post locally
              api.fetchPosts(forceRefresh: true);
              widget.onDelete?.call(); // Call onDelete callback

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Post deleted"),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Delete failed"),
                  backgroundColor: Colors.red,
                ),
              );
            }
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

  // ================= MEDIA CAROUSEL =================
  Widget _buildMediaCarousel(BuildContext context) {
    if (widget.post.media.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1 / 1, // Instagram-style square or 4:5
          child: Stack(
            children: [
              PageView.builder(
                itemCount: widget.post.media.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final media = widget.post.media[index];
                  final isVideo = media.isVideo;

                  return GestureDetector(
                    onDoubleTap: _handleDoubleTap,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(
                            post: widget.post,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isVideo
                            ? VideoPlayerWidget(videoUrl: media.file)
                            : CachedNetworkImage(
                                imageUrl: media.file,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.white),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
              // Double Tap Heart Overlay
              if (_showHeart)
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.5).animate(
                      CurvedAnimation(
                        parent: _heartController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 90,
                    ),
                  ),
                ),
              // Current Page Text Indicator (Top Right)
              if (widget.post.media.length > 1)
                Positioned(
                  top: 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1}/${widget.post.media.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Dot Indicators (Bottom)
        if (widget.post.media.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.post.media.length, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  height: 6,
                  width: isSelected ? 12 : 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
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
