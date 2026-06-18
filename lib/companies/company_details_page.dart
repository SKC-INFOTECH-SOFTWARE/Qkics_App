import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/models/company.dart';
import 'package:q_kics/models/company_post.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/companies/create_company_post_page.dart';
import 'package:q_kics/companies/create_company_page.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/companies/widgets/company_post_card.dart';
import 'package:q_kics/home/post_shimmer.dart';

class CompanyDetailsPage extends StatefulWidget {
  final Company company;

  const CompanyDetailsPage({Key? key, required this.company}) : super(key: key);

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<CompanyPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = context.read<CompanyProvider>().fetchCompanyPosts(
      widget.company.id,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currentUser = context.watch<ApiProvider>().currentUser;

    bool canManage = false;
    if (currentUser != null) {
      if (widget.company.owner.toLowerCase().startsWith(
        currentUser.username.toLowerCase(),
      )) {
        canManage = true;
      } else {
        final memberIdx = widget.company.members.indexWhere((m) {
          if (m.user != null) {
            return m.user!.uuid == currentUser.uuid ||
                m.user!.username == currentUser.username;
          } else if (m.userString != null) {
            return m.userString == currentUser.username;
          }
          return false;
        });
        if (memberIdx != -1) {
          final role = widget.company.members[memberIdx].role.toLowerCase();
          canManage = role == 'owner' || role == 'editor';
        }
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateCompanyPostPage(companyId: widget.company.id),
                  ),
                );
                if (result == true) {
                  setState(() {
                    _loadPosts(); // Reload posts if new post was added
                  });
                }
              },
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.post_add, color: Colors.white),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              actions: [
                if (canManage)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateCompanyPage(company: widget.company),
                          ),
                        );
                        if (updated != null && mounted) {
                          Navigator.pop(
                            context,
                          ); // Return to previous to refresh list
                        }
                      } else if (value == 'delete') {
                        final provider = context.read<CompanyProvider>();
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Company'),
                            content: const Text(
                              'Are you sure you want to delete this company?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final success = await provider.deleteCompany(
                            widget.company.id,
                          );
                          if (success && mounted) {
                            Navigator.pop(context);
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Company'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Company',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover Image
                    widget.company.coverImage != null
                        ? CachedNetworkImage(
                            imageUrl: widget.company.coverImage!,
                            fit: BoxFit.cover,
                            color: Colors.black.withValues(alpha: 0.3),
                            colorBlendMode: BlendMode.darken,
                          )
                        : Container(
                            color: colorScheme.primary.withValues(alpha: 0.8),
                          ),

                    // Logo and Title Overlay
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.surface,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.company.logo != null
                                  ? CachedNetworkImage(
                                      imageUrl: widget.company.logo!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.business,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.company.name,
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.company.industry,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _ChipTabDelegate(
                tabController: _tabController,
                tabs: const [
                  (label: 'Posts', icon: Icons.article_outlined),
                  (label: 'About', icon: Icons.info_outline),
                ],
                backgroundColor: theme.scaffoldBackgroundColor,
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(canManage),
            _buildAboutTab(textTheme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab(bool canManage) {
    final theme = Theme.of(context);

    return FutureBuilder<List<CompanyPost>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        // ── Loading ───────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            itemCount: 3,
            itemBuilder: (_, __) => const PostShimmer(),
          );
        }

        // ── Error ─────────────────────────────────────────────
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text("Couldn't load posts.", style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _loadPosts()),
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        // ── Empty ─────────────────────────────────────────────
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.feed_outlined,
                  size: 60,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "No posts yet.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        // ── Feed ──────────────────────────────────────────────
        return ListView.builder(
          padding: EdgeInsets.only(
            left: 2,
            right: 2,
            top: 8,
            bottom: canManage ? 96 : 16,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return CompanyPostCard(
              post: post,
              showCompanyHeader: false,
              onEdit: canManage
                  ? () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateCompanyPostPage(
                            companyId: widget.company.id,
                            post: post,
                          ),
                        ),
                      );
                      if (updated == true && mounted) setState(() => _loadPosts());
                    }
                  : null,
              onDelete: canManage
                  ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Post'),
                          content: const Text(
                            'Are you sure you want to delete this post?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        final success = await context
                            .read<CompanyProvider>()
                            .deleteCompanyPost(post.id);
                        if (success) setState(() => _loadPosts());
                      }
                    }
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab(TextTheme textTheme, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(textTheme, "Overview"),
          const SizedBox(height: 8),
          Text(widget.company.description, style: textTheme.bodyLarge),
          const SizedBox(height: 24),

          _buildSectionTitle(textTheme, "Details"),
          const SizedBox(height: 12),
          Card(
            elevation: theme.brightness == Brightness.dark ? 6 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _detailTile(
                    theme,
                    Icons.language,
                    "Website",
                    widget.company.website,
                  ),
                  _detailTile(
                    theme,
                    Icons.location_on_outlined,
                    "Location",
                    widget.company.location,
                  ),
                  _detailTile(
                    theme,
                    Icons.people_outline,
                    "Company Size",
                    "${widget.company.members.length} members",
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          _buildSectionTitle(textTheme, "Team Members"),
          const SizedBox(height: 12),
          if (widget.company.members.isEmpty)
            Text(
              "No members available",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Card(
              elevation: theme.brightness == Brightness.dark ? 6 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.company.members.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final member = widget.company.members[index];
                    final name =
                        member.user?.fullName ??
                        member.userString ??
                        'Unknown';
                    final imageUrl = member.user?.profileImage;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        backgroundImage: imageUrl != null
                            ? CachedNetworkImageProvider(imageUrl)
                            : null,
                        child: imageUrl == null
                            ? Icon(
                                Icons.person,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        member.role,
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Text(
      title,
      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _detailTile(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 52,
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

class _ChipTabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<({String label, IconData icon})> tabs;
  final Color backgroundColor;

  const _ChipTabDelegate({
    required this.tabController,
    required this.tabs,
    required this.backgroundColor,
  });

  static const double _height = 52.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final selected = tabController.index;
        return Container(
          height: _height,
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final isSelected = selected == i;
                return Padding(
                  padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => tabController.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tabs[i].icon,
                            size: 15,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tabs[i].label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(_ChipTabDelegate old) =>
      old.tabController != tabController ||
      old.tabs != tabs ||
      old.backgroundColor != backgroundColor;
}
