import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';

import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/home/comment_sheet.dart';
import 'package:q_kics/home/post_detail_page.dart';
import 'package:q_kics/profile/ui/widgets/public/public_profile_page.dart';
import 'package:q_kics/home/create_post_page.dart';
import 'package:q_kics/widgets/video_player_widget.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final int currentUserId;

  const PostCard({super.key, required this.post, required this.currentUserId});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final ValueNotifier<bool> _isExpanded = ValueNotifier(false);
  late PageController _mediaPageController;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController();
  }

  @override
  void dispose() {
    _isExpanded.dispose();
    _mediaPageController.dispose();
    super.dispose();
  }

  void _openPublicProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfilePage(username: username)),
    );
  }

  Color _userTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'expert':
        return Colors.blue;
      case 'entrepreneur':
        return Colors.green;
      case 'investor':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAvatar(String? imageUrl, String username, double radius) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : "U";
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.15),
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 1.1,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          width: radius * 2,
          height: radius * 2,
          memCacheWidth: (radius * 2 * MediaQuery.of(context).devicePixelRatio)
              .toInt(),
          memCacheHeight: (radius * 2 * MediaQuery.of(context).devicePixelRatio)
              .toInt(),
          placeholder: (_, __) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.15),
            child: Text(initial),
          ),
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.15),
            child: Text(initial),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colorScheme = Theme.of(context).colorScheme;
    final hasTitle = post.title?.trim().isNotEmpty ?? false;
    final timeAgo = timeago.format(post.createdAt);
    final api = Provider.of<ApiProvider>(context, listen: false);

    // Dynamic scale for tablets
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final double scale = isTablet ? 1.4 : 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openPublicProfile(post.author.username),
                  child: _buildAvatar(
                    post.author.profileImage,
                    post.author.username,
                    24 * scale,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _openPublicProfile(post.author.username),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scale,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "$timeAgo • ",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13 * scale,
                                ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _userTypeColor(
                                      post.author.userTypeDisplay,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _userTypeColor(
                                        post.author.userTypeDisplay,
                                      ).withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    post.author.userTypeDisplay,
                                    style: TextStyle(
                                      color: _userTypeColor(
                                        post.author.userTypeDisplay,
                                      ),
                                      fontSize: 11 * scale,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (post.author.id == widget.currentUserId)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreatePostPage(postToEdit: post),
                          ),
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Post"),
                            content: const Text(
                              "Are you sure you want to delete this post?",
                            ),
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

                        if (confirm == true && mounted) {
                          final api = context.read<ApiProvider>();
                          final success = await api.deletePost(post.id);
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Post deleted successfully"),
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text("Edit"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text("Delete", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (hasTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                post.title!,
                style: GoogleFonts.merriweather(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isExpanded,
              builder: (context, expanded, _) {
                final showReadMore = post.content.length > 180;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content,
                      style: TextStyle(fontSize: 14.5 * scale, height: 1.65),
                      maxLines: expanded ? null : 3,
                      overflow: expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (showReadMore)
                      GestureDetector(
                        onTap: () => _isExpanded.value = !expanded,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            expanded ? "Show less" : "Read more",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * scale,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: post.tags
                    .map(
                      (tag) => InkWell(
                        onTap: () =>
                            api.fetchPosts(forceRefresh: true, tag: tag.name),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '#${tag.name}',
                            style: TextStyle(
                              fontSize: 13.5 * scale,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          _buildMedia(post, scale),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final wasLiked = post.isLiked;
                    final newLikes = wasLiked
                        ? post.totalLikes - 1
                        : post.totalLikes + 1;
                    setState(() {
                      post.isLiked = !wasLiked;
                      post.totalLikes = newLikes;
                    });
                    await api.togglePostLike(post.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          color: post.isLiked ? Colors.red : Colors.grey[600],
                          size: 20 * scale,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${post.totalLikes} Like${post.totalLikes == 1 ? '' : 's'}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: post.isLiked ? Colors.red : Colors.grey[600],
                            fontSize: 14 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
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
                      Icon(
                        Icons.comment_outlined,
                        size: 20 * scale,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${post.totalComments} Comment${post.totalComments == 1 ? '' : 's'}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMedia(Post post, double scale) {
    if (post.media.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 0.9, // Instagram square style
          child: Stack(
            children: [
              PageView.builder(
                controller: _mediaPageController,
                itemCount: post.media.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentMediaIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final media = post.media[index];
                  return _buildMediaItem(media, post.id);
                },
              ),
              // Page Count Overlay (Top Right)
              if (post.media.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
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
                      '${_currentMediaIndex + 1}/${post.media.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Dots Indicator Overlay (Bottom Center)
              if (post.media.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      post.media.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _currentMediaIndex == index ? 8 : 6,
                        height: _currentMediaIndex == index ? 8 : 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentMediaIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withOpacity(0.5),
                          boxShadow: [
                            if (_currentMediaIndex == index)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaItem(PostMedia media, int postId) {
    return GestureDetector(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: media.isVideo
            ? VideoPlayerWidget(
                videoUrl: media.file,
                aspectRatio: 0.9,
                fit: BoxFit.contain,
                autoPlay: true,
                mute: true,
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
              )
            : CachedNetworkImage(
                imageUrl: media.file,

                fit: BoxFit.contain,
                width: double.infinity,
                memCacheWidth: 800,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
