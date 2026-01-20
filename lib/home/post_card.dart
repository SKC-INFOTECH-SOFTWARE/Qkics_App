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

class PostCard extends StatefulWidget {
  final Post post;
  final int currentUserId;

  const PostCard({super.key, required this.post, required this.currentUserId});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final ValueNotifier<bool> _isExpanded = ValueNotifier(false);

  @override
  void dispose() {
    _isExpanded.dispose();
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
          fit: BoxFit.cover,
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
          if (post.image != null && post.image!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailPage(
                      post: post,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'post_image_${post.id}',
                child: CachedNetworkImage(
                  imageUrl: post.image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 800, // Balanced for quality and memory
                  cacheKey: post.image, // Ensure stable cache hitting
                  fadeInDuration: const Duration(milliseconds: 400),
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 280,
                      decoration: const BoxDecoration(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 280,
                    decoration: BoxDecoration(color: Colors.grey[200]),
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
            ),
          ],
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
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked ? Colors.red : Colors.grey[600],
                          size: 20 * scale,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${post.totalLikes} Upvote${post.totalLikes == 1 ? '' : 's'}",
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
                        "${post.totalComments} Answer${post.totalComments == 1 ? '' : 's'}",
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
}
