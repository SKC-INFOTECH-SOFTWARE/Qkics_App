/// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/providers/notification_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/home/home_side_menu.dart';
import 'package:q_kics/home/search_page.dart';
import 'package:q_kics/home/create_post_page.dart';
import 'package:q_kics/home/post_card.dart';
import 'package:q_kics/models/user.dart';
import 'package:q_kics/home/post_shimmer.dart';

class HomePage extends StatefulWidget {
  final ScrollController? scrollController;
  final ValueChanged<bool>?
  onBarsVisibilityChanged; // true = visible, false = hidden

  const HomePage({
    super.key,
    this.scrollController,
    this.onBarsVisibilityChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ScrollController _scrollController;

  bool _isAppBarVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
  }

  // Only used for infinite-scroll pagination now.
  // Hide/show is handled by UserScrollNotification in _buildFeed.
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final api = Provider.of<ApiProvider>(context, listen: false);
      if (api.hasMore && !api.isLoadingMore) {
        api.fetchPosts();
      }
    }
  }

  void _onUserScroll(UserScrollNotification notification) {
    final pixels = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;

    if (notification.direction == ScrollDirection.reverse && pixels > 80) {
      // Scrolling down and not near the top → hide
      if (_isAppBarVisible) {
        setState(() => _isAppBarVisible = false);
        widget.onBarsVisibilityChanged?.call(false);
      }
    } else if (notification.direction == ScrollDirection.forward) {
      // Scrolling up → show
      if (!_isAppBarVisible) {
        setState(() => _isAppBarVisible = true);
        widget.onBarsVisibilityChanged?.call(true);
      }
    }
  }

  Future<void> _loadInitialData() async {
    final api = Provider.of<ApiProvider>(context, listen: false);
    final user = await api.getCurrentUser();
    await api.fetchPosts(forceRefresh: true);

    if (user != null && mounted) {
      if (!context.mounted) return;
      context.read<NotificationProvider>().init(user.id.toString());
    }
  }

  Future<void> _onRefresh() async {
    final api = Provider.of<ApiProvider>(context, listen: false);
    await api.fetchPosts(forceRefresh: true);
    api.getCurrentUser();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Widget _buildAvatar(String? imageUrl, String username, double radius) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : "U";
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final double scale = isTablet ? 1.4 : 1.0;
    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
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
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: radius * 2 * scale,
          height: radius * 2 * scale,
          memCacheWidth:
              (radius * 2 * scale * MediaQuery.of(context).devicePixelRatio)
                  .toInt(),
          memCacheHeight:
              (radius * 2 * scale * MediaQuery.of(context).devicePixelRatio)
                  .toInt(),
          placeholder: (_, __) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(initial),
          ),
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(initial),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final api = Provider.of<ApiProvider>(context);
    final user = api.currentUser;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final double scale = isTablet ? 1.4 : 1.0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: _isAppBarVisible
          ? PreferredSize(
              preferredSize: Size.fromHeight(56.0 * scale),
              child: AnimatedOpacity(
                opacity: _isAppBarVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AppBar(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  leading: Padding(
                    padding: EdgeInsets.all(8.0 / scale),
                    child: GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: _buildAvatar(
                        user?.profileImage,
                        user?.username ?? "",
                        20 * scale,
                      ),
                    ),
                  ),
                  title: Text(
                    "Q-KICS",
                    style: GoogleFonts.aDLaMDisplay(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.search, size: 28 * scale),
                      color: colorScheme.primary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchPage(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add_box_outlined, size: 30 * scale),
                      color: colorScheme.primary,
                      tooltip: "Create Post",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreatePostPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            )
          : null,
      drawer: Drawer(
        width: isTablet ? width * 0.45 : null,
        child: const HomeSideMenu(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (() {
              final w = MediaQuery.of(context).size.width;
              if (w >= 1200) return 1000.0; // large tablets / small desktops
              if (w >= 900) return 900.0; // medium tablets
              if (w >= 600) return 800.0; // small tablets
              return double.infinity; // phones: no max constraint
            })(),
          ),
          child: _buildFeed(api, colorScheme, user),
        ),
      ),
    );
  }

  Widget _buildFeed(ApiProvider api, ColorScheme colorScheme, User? user) {
    final posts = api.posts;
    return NotificationListener<UserScrollNotification>(
      onNotification: (n) {
        _onUserScroll(n);
        return false; // let the notification keep bubbling
      },
      child: RefreshIndicator(
      onRefresh: _onRefresh,
      color: colorScheme.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 40,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        cacheExtent: 2500,
        slivers: [
          // ================= APPBAR (Pinned Time Portion) =================
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            toolbarHeight: 0, // Keep only status bar background
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),

          if (api.selectedTag != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Filtered by #${api.selectedTag}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => api.clearTag(),
                      icon: const Icon(Icons.close, size: 20),
                      color: colorScheme.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          if (posts.isEmpty && (api.isLoadingMore || !api.hasFetchedPosts))
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const PostShimmer(),
                  childCount: 3,
                ),
              ),
            )
          else if (posts.isEmpty && api.hasFetchedPosts && !api.isLoadingMore)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No questions yet.\nBe the first to ask!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == posts.length) {
                      return api.hasMore
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 0),
                              child: PostShimmer(),
                            )
                          : const SizedBox(height: 80);
                    }
                    final post = posts[index];
                    return PostCard(post: post, currentUserId: user?.id ?? 0);
                  },
                  childCount: posts.length + (api.hasMore ? 1 : 0),
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
        ],
      ),
    ));
  }
}
