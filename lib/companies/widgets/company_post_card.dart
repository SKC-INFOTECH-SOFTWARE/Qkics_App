import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:q_kics/models/company_post.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/companies/company_details_page.dart';
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
  static const double _kVideoAspectRatio = 4.0 / 5.0;
  static const double _kImageAspectRatioFallback = 1.0;

  double? _detectedImageRatio;
  late final PageController _mediaPageController;
  final ValueNotifier<bool> _isExpanded = ValueNotifier(false);
  int _currentMediaIndex = 0;

  bool get _canManage => widget.onEdit != null || widget.onDelete != null;

  @override
  void initState() {
    super.initState();
    _mediaPageController = PageController();

    final media = widget.post.media;
    if (media.isNotEmpty && !media.first.isVideo) {
      _detectImageRatio(media.first.file);
    }
  }

  void _detectImageRatio(String imageUrl) {
    final provider = CachedNetworkImageProvider(imageUrl);
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          final w = info.image.width.toDouble();
          final h = info.image.height.toDouble();
          setState(() {
            _detectedImageRatio = (w / h).clamp(4.0 / 5.0, 16.0 / 9.0);
          });
        }
        stream.removeListener(listener);
      },
      onError: (_, __) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _isExpanded.dispose();
    _mediaPageController.dispose();
    super.dispose();
  }

  Future<void> _openCompanyDetails() async {
    final slug = widget.post.company.slug;
    if (slug.isEmpty) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<CompanyProvider>();

    final company = await provider.fetchCompanyDetails(slug);
    if (!mounted) return;

    if (company == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open company')),
      );
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(company: company),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colorScheme = Theme.of(context).colorScheme;
    final hasTitle = post.title.trim().isNotEmpty;
    final timeAgo = timeago.format(post.createdAt);

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

          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.showCompanyHeader ? _openCompanyDetails : null,
                  child: _buildAvatar(post, 24 * scale),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: widget.showCompanyHeader
                            ? _openCompanyDetails
                            : null,
                        child: Text(
                          widget.showCompanyHeader
                              ? post.company.name
                              : post.author,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scale,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$timeAgo • ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13 * scale,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.indigo.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'Company',
                              style: TextStyle(
                                color: Colors.indigo,
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_canManage)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit?.call();
                      if (value == 'delete') widget.onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Title ──────────────────────────────────────────
          if (hasTitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                post.title,
                style: GoogleFonts.merriweather(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // ── Content with See more / See less ──────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isExpanded,
              builder: (context, expanded, _) {
                final collapsible = post.content.length > 120 ||
                    post.content.contains('\n');
                final collapse = collapsible && !expanded;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content,
                      style: TextStyle(fontSize: 14.5 * scale, height: 1.65),
                      maxLines: collapse ? 3 : null,
                      overflow:
                          collapse ? TextOverflow.ellipsis : TextOverflow.visible,
                    ),
                    if (collapsible)
                      GestureDetector(
                        onTap: () => _isExpanded.value = !expanded,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            expanded ? 'See less' : 'See more',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5 * scale,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Media ──────────────────────────────────────────
          if (post.media.isNotEmpty) _buildMedia(post, scale),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Avatar: company logo or letter fallback ───────────────
  Widget _buildAvatar(CompanyPost post, double radius) {
    final initial =
        post.company.name.isNotEmpty ? post.company.name[0].toUpperCase() : 'C';
    final hasLogo =
        post.company.logo != null && post.company.logo!.trim().isNotEmpty;

    if (!hasLogo) {
      return CircleAvatar(
        radius: radius,
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius,
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
          imageUrl: post.company.logo!,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          placeholder: (_, __) => CircleAvatar(
            radius: radius,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(initial),
          ),
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(initial),
          ),
        ),
      ),
    );
  }

  // ── Media section matching home PostCard exactly ──────────
  Widget _buildMedia(CompanyPost post, double scale) {
    final boxRatio = post.media.first.isVideo
        ? _kVideoAspectRatio
        : (_detectedImageRatio ?? _kImageAspectRatioFallback);

    return Column(
      children: [
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: boxRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _mediaPageController,
                itemCount: post.media.length,
                onPageChanged: (index) =>
                    setState(() => _currentMediaIndex = index),
                itemBuilder: (context, index) =>
                    _buildMediaItem(post.media[index]),
              ),
              // Page counter badge (top-right)
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
                      color: Colors.black.withValues(alpha: 0.6),
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
              // Dot indicators (bottom-center)
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
                              : Colors.white.withValues(alpha: 0.5),
                          boxShadow: [
                            if (_currentMediaIndex == index)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
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

  Widget _buildMediaItem(PostMedia media) {
    if (media.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: VideoPlayerWidget(
                videoUrl: media.file,
                fit: BoxFit.cover,
                autoPlay: true,
                mute: true,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.25)),
          VideoPlayerWidget(
            videoUrl: media.file,
            fit: BoxFit.cover,
            autoPlay: true,
            mute: true,
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred backdrop
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: CachedNetworkImage(
              imageUrl: media.file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.08)),
        // Main image
        CachedNetworkImage(
          imageUrl: media.file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: (MediaQuery.of(context).size.width *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt()
              .clamp(800, 2160),
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
      ],
    );
  }
}
