import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/home/post_card.dart';
import 'package:q_kics/home/post_shimmer.dart';
import 'package:q_kics/home/create_post_page.dart';
import 'package:q_kics/documents/ui/knowledge_hub_page.dart';

/// A controller that holds both the outer (Hub Posts / Documents) tab index
/// and a page-level state for the documents sub-tabs.
class KnowledgeHubPostsPage extends StatefulWidget {
  /// When true the page is hosted inside the main bottom-nav shell: it drops its
  /// own back button and floating bottom bar (those belong to the shell) and
  /// shows an inline Hub Posts / Documents switch instead.
  final bool embedded;

  const KnowledgeHubPostsPage({super.key, this.embedded = false});

  @override
  State<KnowledgeHubPostsPage> createState() => _KnowledgeHubPostsPageState();
}

class _KnowledgeHubPostsPageState extends State<KnowledgeHubPostsPage>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;

  // ── Outer nav: 0 = Hub Posts, 1 = Documents ──────────────────────────────
  int _outerIndex = 0;

  // ── Inner doc tabs controller (passed to embedded KnowledgeHubPage) ──────
  late final TabController _docTabController;

  // ── Post feed search ──────────────────────────────────────────────────────
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _docTabController = TabController(length: 3, vsync: this);
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final api = Provider.of<ApiProvider>(context, listen: false);
      if (api.khHasMore && !api.khIsLoadingMore) {
        api.fetchKnowledgeHubPosts();
      }
    }
  }

  Future<void> _loadInitialData() async {
    final api = Provider.of<ApiProvider>(context, listen: false);
    await api.fetchKnowledgeHubPosts(forceRefresh: true);
  }

  Future<void> _onRefresh() async {
    final api = Provider.of<ApiProvider>(context, listen: false);
    await api.fetchKnowledgeHubPosts(forceRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _docTabController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final api = Provider.of<ApiProvider>(context);
    final allPosts = api.knowledgeHubPosts;
    final user = api.currentUser;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final double scale = isTablet ? 1.4 : 1.0;

    // Client-side search filter for Hub Posts tab
    final posts = _searchQuery.isEmpty
        ? allPosts
        : allPosts.where((p) {
            final q = _searchQuery.toLowerCase();
            return (p.title?.toLowerCase().contains(q) ?? false) ||
                p.content.toLowerCase().contains(q);
          }).toList();

    // AppBar title changes depending on the active tab
    final isDocTab = _outerIndex == 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
              ),
        title: isDocTab
            ? Text(
                'Document Hub',
                style: GoogleFonts.aDLaMDisplay(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              )
            : _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search posts…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16 * scale,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(
                'Knowledge Hub',
                style: GoogleFonts.aDLaMDisplay(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
        centerTitle: !(!isDocTab && _showSearchBar),
        // Show search + add only on Hub Posts tab
        actions: isDocTab
            ? []
            : [
                IconButton(
                  icon: Icon(
                    _showSearchBar ? Icons.close : Icons.search,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = !_showSearchBar;
                      if (!_showSearchBar) {
                        _searchController.clear();
                        _searchQuery = '';
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Add Post',
                  onPressed: () async {
                    final api = context.read<ApiProvider>();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const CreatePostPage(initialKnowledgeHub: true),
                      ),
                    );
                    // Refresh the Knowledge Hub feed after returning so a newly
                    // created post shows up.
                    await api.fetchKnowledgeHubPosts(forceRefresh: true);
                  },
                ),
              ],
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: Column(
        children: [
          // Inline Hub Posts / Documents switch (only when embedded as a tab,
          // since the standalone page uses its own floating bottom bar).
          if (widget.embedded) _outerSwitch(colorScheme),
          Expanded(
            child: IndexedStack(
        index: _outerIndex,
        children: [
          // ── Tab 0: Hub Posts feed ─────────────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (() {
                  if (width >= 1200) return 1000.0;
                  if (width >= 900) return 900.0;
                  if (width >= 600) return 800.0;
                  return double.infinity;
                })(),
              ),
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: colorScheme.primary,
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (posts.isEmpty && api.khIsLoadingMore)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, __) => const PostShimmer(),
                            childCount: 3,
                          ),
                        ),
                      )
                    else if (posts.isEmpty && !api.khIsLoadingMore)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No Knowledge Hub posts yet.'
                                    : 'No posts match "$_searchQuery".',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == posts.length) {
                                return api.khHasMore
                                    ? const PostShimmer()
                                    : const SizedBox(height: 100);
                              }
                              return PostCard(
                                post: posts[index],
                                currentUserId: user?.id ?? 0,
                              );
                            },
                            childCount: posts.length + (api.khHasMore ? 1 : 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab 1: Document Hub (embedded — no extra Scaffold/AppBar) ─────
          KnowledgeHubPage(
            embedded: true,
            tabController: _docTabController,
            // Clear the shell's floating nav bar when hosted in the bottom nav.
            contentBottomInset: widget.embedded ? 100 : 0,
          ),
        ],
      ),
          ),
        ],
      ),

      // ── Floating bottom nav bar (standalone only) ──────────────────────────
      bottomNavigationBar: widget.embedded
          ? null
          : Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _navItem(
                    icon: Icons.forum_outlined,
                    activeIcon: Icons.forum,
                    label: 'Hub Posts',
                    index: 0,
                    colorScheme: colorScheme,
                  ),
                  _navItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book,
                    label: 'Documents',
                    index: 1,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Inline segmented switch shown at the top when [widget.embedded] is true.
  Widget _outerSwitch(ColorScheme cs) {
    Widget seg(String label, IconData icon, int index) {
      final isActive = _outerIndex == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _outerIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? cs.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg('Hub Posts', Icons.forum_outlined, 0),
          const SizedBox(width: 4),
          seg('Documents', Icons.menu_book_outlined, 1),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required ColorScheme colorScheme,
  }) {
    final isActive = _outerIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _outerIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? colorScheme.primary : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
