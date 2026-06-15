import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/models/company_post.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/widgets/video_player_widget.dart';

class CompanyPostsPage extends StatefulWidget {
  const CompanyPostsPage({super.key});

  @override
  State<CompanyPostsPage> createState() => _CompanyPostsPageState();
}

class _CompanyPostsPageState extends State<CompanyPostsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().fetchAllCompanyPosts(forceRefresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<CompanyProvider>();
      if (!provider.isLoadingGlobalPosts && provider.hasMoreGlobalPosts) {
        provider.fetchAllCompanyPosts();
      }
    }
  }

  Future<void> _onRefresh() async {
    await context.read<CompanyProvider>().fetchAllCompanyPosts(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanyProvider>(
      builder: (context, provider, child) {
        final posts = provider.globalPosts;
        final isLoading = provider.isLoadingGlobalPosts;

        if (isLoading && posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (posts.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text("No posts from companies yet.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: posts.length + (provider.hasMoreGlobalPosts ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final post = posts[index];
              return _GlobalCompanyPostCard(post: post);
            },
          ),
        );
      },
    );
  }
}

class _GlobalCompanyPostCard extends StatelessWidget {
  final CompanyPost post;

  const _GlobalCompanyPostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: post.company.logo != null ? NetworkImage(post.company.logo!) : null,
                  child: post.company.logo == null
                      ? Icon(Icons.business, color: colorScheme.onSurfaceVariant, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.company.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(post.content),
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.media.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, mIdx) {
                    final isVideo = post.media[mIdx].isVideo;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isVideo
                          ? SizedBox(
                              width: 200,
                              child: VideoPlayerWidget(videoUrl: post.media[mIdx].file),
                            )
                          : CachedNetworkImage(
                              imageUrl: post.media[mIdx].file,
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                    );
                  },
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
    } else {
      return "Just now";
    }
  }
}
