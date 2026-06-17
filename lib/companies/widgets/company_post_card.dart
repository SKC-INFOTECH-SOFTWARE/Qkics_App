import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/models/company_post.dart';
import 'package:q_kics/models/post.dart';
import 'package:shimmer/shimmer.dart';
import 'package:q_kics/widgets/video_player_widget.dart';

class CompanyPostCard extends StatefulWidget {
  final CompanyPost post;

  /// Show the company name/logo header (used in the cross-company feed).
  /// Hidden when already viewing a single company's own Posts tab.
  final bool showCompanyHeader;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CompanyPostCard({
    super.key,
    required this.post,
    this.showCompanyHeader = true,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CompanyPostCard> createState() => _CompanyPostCardState();
}

class _CompanyPostCardState extends State<CompanyPostCard> {
  late final PageController _mediaPageController;
  int _currentMediaIndex = 0;

  bool get _canManage => widget.onEdit != null || widget.onDelete != null;

  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController();
  }

  @override
  void dispose() {
    _mediaPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final post = widget.post;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      elevation: theme.brightness == Brightness.dark ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showCompanyHeader) ...[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: post.company.logo != null
                        ? CachedNetworkImageProvider(post.company.logo!)
                        : null,
                    child: post.company.logo == null
                        ? Icon(
                            Icons.business,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showCompanyHeader)
                        Text(
                          post.company.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        post.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canManage)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit?.call();
                      if (value == 'delete') widget.onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Post'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Post',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: theme.textTheme.bodyMedium),
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: PageView.builder(
                          controller: _mediaPageController,
                          itemCount: post.media.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentMediaIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final media = post.media[index];
                            return _buildMediaItem(media);
                          },
                        ),
                      ),
                    ),
                    if (post.media.length > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentMediaIndex + 1}/${post.media.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (post.media.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(post.media.length, (index) {
                            final isActive = _currentMediaIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      if (diff.inDays > 30) {
        return "${date.day}/${date.month}/${date.year}";
      }
      return "${diff.inDays}d ago";
    } else if (diff.inHours > 0) {
      return "${diff.inHours}h ago";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes}m ago";
    }
    return "Just now";
  }

  Widget _buildMediaItem(PostMedia media) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: media.isVideo
          ? VideoPlayerWidget(
              videoUrl: media.file,
              aspectRatio: 0.9,
              fit: BoxFit.contain,
              autoPlay: true,
              mute: true,
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
    );
  }
}
