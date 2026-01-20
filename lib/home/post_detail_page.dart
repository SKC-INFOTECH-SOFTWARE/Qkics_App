/// lib/screens/post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/home/comment_sheet.dart';
import 'package:photo_view/photo_view.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;
  final int currentUserId;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  late Post post;
  late ApiProvider api;
  late AnimationController _heartController;

  bool _showUI = true;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    api = Provider.of<ApiProvider>(context, listen: false);

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

  void _toggleLike() async {
    final wasLiked = post.isLiked;
    setState(() {
      post.isLiked = !wasLiked;
      post.totalLikes = wasLiked ? post.totalLikes - 1 : post.totalLikes + 1;
    });

    if (!wasLiked) {
      setState(() => _showHeart = true);
      _heartController.forward(from: 0.0).then((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _showHeart = false);
        });
      });
    }
    await api.togglePostLike(post.id);
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isDark ? Colors.black : Colors.white;
    final overlayColor = isDark ? Colors.black54 : Colors.white70;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final tagColor = colorScheme.tertiary;
    final ValueNotifier<bool> isExpanded = ValueNotifier(false);
    final timeAgo = timeago.format(post.createdAt);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Full-screen zoomable image
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleUI,
              onDoubleTap: _toggleLike,
              child: post.image != null
                  ? PhotoView(
                      imageProvider: CachedNetworkImageProvider(post.image!),
                      heroAttributes: PhotoViewHeroAttributes(
                        tag: 'post_image_${post.id}',
                      ),
                      backgroundDecoration: BoxDecoration(color: bgColor),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: 4.0,
                      gestureDetectorBehavior: HitTestBehavior.opaque,
                    )
                  : Container(color: bgColor),
            ),
          ),

          // Double-tap heart animation
          if (_showHeart)
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.5).animate(
                  CurvedAnimation(
                    parent: _heartController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: const Icon(Icons.favorite, color: Colors.red, size: 110),
              ),
            ),

          // Top Bar (Back + More)
          AnimatedOpacity(
            opacity: _showUI ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: overlayColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: textColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: overlayColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.more_horiz, color: textColor, size: 26),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom overlay - fully adaptive
          AnimatedSlide(
            duration: const Duration(milliseconds: 350),
            offset: _showUI ? Offset.zero : const Offset(0, 1),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 30 + MediaQuery.of(context).padding.bottom,
                    top: 30,
                  ),
                  decoration: BoxDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author + Time
                      Row(
                        children: [
                          Text(
                            post.author.fullName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "· $timeAgo",
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Title
                      if (post.title?.trim().isNotEmpty == true) ...[
                        Text(
                          post.title ?? "",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],

                      // Content
                      ValueListenableBuilder<bool>(
                        valueListenable: isExpanded,
                        builder: (context, expanded, _) {
                          final showReadMore = post.content.length > 180;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.content,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  height: 1.65,
                                ),
                                maxLines: expanded ? null : 3,
                                overflow: expanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                              ),
                              if (showReadMore)
                                GestureDetector(
                                  onTap: () => isExpanded.value = !expanded,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      expanded ? "Show less" : "Read more",
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 6),

                      // Tags
                      if (post.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          children: post.tags
                              .map(
                                (tag) => Text(
                                  '#${tag.name}',
                                  style: TextStyle(
                                    color: tagColor,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Upvote
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  post.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: post.isLiked ? Colors.red : textColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  post.totalLikes > 0
                                      ? '${post.totalLikes}'
                                      : 'Upvote',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Comments
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
                                  color: textColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  post.totalComments > 0
                                      ? '${post.totalComments}'
                                      : 'Answer',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Share
                          Row(
                            children: [
                              Icon(
                                Icons.share_outlined,
                                color: textColor,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Share",
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
