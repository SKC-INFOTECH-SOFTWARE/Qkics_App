import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/companies/widgets/company_post_card.dart';

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
    final theme = Theme.of(context);
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
                      Icon(
                        Icons.article_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No posts from companies yet.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
              return CompanyPostCard(post: post);
            },
          ),
        );
      },
    );
  }
}
