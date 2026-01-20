import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/home/post_card.dart';
import 'package:q_kics/profile/ui/widgets/public/public_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;
  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  String _currentQuery = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _currentQuery) {
      if (query.length >= 3) {
        _currentQuery = query;
        _performSearch(query);
      } else {
        if (_currentQuery.isNotEmpty) {
          _currentQuery = "";
          final api = context.read<ApiProvider>();
          api.clearSearchResults();
          api.clearUserSearchResults();
          setState(() {});
        }
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (mounted) setState(() => _isSearching = true);
    final api = context.read<ApiProvider>();

    try {
      await Future.wait([api.searchPosts(query), api.searchUsers(query)]);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openPublicProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfilePage(username: username)),
    );
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = context.watch<ApiProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildResponsiveAppBar(theme),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          child: _searchController.text.length < 3
              ? _buildInitialState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // POSTS → SAME AS HOME PAGE
                    api.searchResults.isEmpty && !_isSearching
                        ? _buildEmptyState("No posts found")
                        : _buildPostsFeed(api),

                    // PEOPLE → CENTERED SINGLE COLUMN ON TABLET
                    api.userSearchResults.isEmpty && !_isSearching
                        ? _buildEmptyState("No people found")
                        : _buildPeople(api.userSearchResults),
                  ],
                ),
        ),
      ),
    );
  }

  // ───────────────────────── RESPONSIVE WIDTH ─────────────────────────

  double _maxWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 1000;
    if (w >= 900) return 900;
    if (w >= 600) return 800;
    return double.infinity;
  }

  // ───────────────────────── APP BAR ─────────────────────────

  PreferredSizeWidget _buildResponsiveAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _maxWidth(context)),
          child: Container(
            height: 48,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              style: TextStyle(fontSize: _isTablet(context) ? 18 : 16),
              decoration: InputDecoration(
                hintText: "Search posts, people...",
                hintStyle: TextStyle(fontSize: _isTablet(context) ? 18 : 16),
                prefixIcon: Icon(
                  Icons.search,
                  size: _isTablet(context) ? 26 : 22,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxWidth(context)),
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: _isTablet(context) ? 18 : 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: _isTablet(context) ? 18 : 14,
              ),
              tabs: const [
                Tab(text: "Posts"),
                Tab(text: "People"),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────── POSTS (LIST LIKE HOME) ─────────────────────────

  Widget _buildPostsFeed(ApiProvider api) {
    final posts = api.searchResults;

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentQuery.isNotEmpty) {
          await _performSearch(_currentQuery);
        }
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostCard(
            post: posts[index],
            currentUserId: api.currentUser?.id ?? 0,
          );
        },
      ),
    );
  }

  // ───────────────────────── PEOPLE (CENTERED) ─────────────────────────

  Widget _buildPeople(List users) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: users.length,
      itemBuilder: (context, i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _UserCard(
            user: users[i],
            onTap: () => _openPublicProfile(users[i].username),
          ),
        );
      },
    );
  }

  // ───────────────────────── STATES ─────────────────────────

  Widget _buildInitialState() {
    return const Center(child: Text("Type at least 3 characters"));
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Text(message));
  }
}

// ───────────────────────── USER CARD ─────────────────────────

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});
  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: (_isTablet(context) ? 34 : 30) * 2,
                height: (_isTablet(context) ? 34 : 30) * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withOpacity(0.15),
                ),
                child: ClipOval(
                  child:
                      user.profileImage != null && user.profileImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.profileImage,
                          fit: BoxFit.cover,
                          memCacheWidth:
                              ((_isTablet(context) ? 34 : 30) *
                                      2 *
                                      MediaQuery.of(context).devicePixelRatio)
                                  .toInt(),
                          memCacheHeight:
                              ((_isTablet(context) ? 34 : 30) *
                                      2 *
                                      MediaQuery.of(context).devicePixelRatio)
                                  .toInt(),
                          placeholder: (_, __) => Center(
                            child: Text(
                              user.username[0].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              user.username[0].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            user.username[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : user.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _isTablet(context) ? 18 : 16,
                      ),
                    ),

                    Text(
                      "@${user.username}",
                      style: TextStyle(
                        fontSize: _isTablet(context) ? 15 : 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.userTypeDisplay,
                  style: TextStyle(
                    fontSize: _isTablet(context) ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
