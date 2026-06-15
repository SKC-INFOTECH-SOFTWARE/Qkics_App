import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/models/company.dart';
import 'package:q_kics/models/company_post.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/companies/create_company_post_page.dart';
import 'package:q_kics/companies/create_company_page.dart';
import 'package:q_kics/providers/api_provider.dart';

class CompanyDetailsPage extends StatefulWidget {
  final Company company;

  const CompanyDetailsPage({Key? key, required this.company}) : super(key: key);

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<CompanyPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = context.read<CompanyProvider>().fetchCompanyPosts(widget.company.id);
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
      if (widget.company.owner.toLowerCase().startsWith(currentUser.username.toLowerCase())) {
        canManage = true;
      } else {
        final memberIdx = widget.company.members.indexWhere((m) {
          if (m.user != null) {
            return m.user!.uuid == currentUser.uuid || m.user!.username == currentUser.username;
          } else if (m.userString != null) {
            return m.userString == currentUser.username;
          }
          return false;
        });
        if (memberIdx != -1) {
          final role = widget.company.members[memberIdx].role.toLowerCase();
          canManage = role == 'owner' || role == 'editor' || role == 'admin';
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
                    builder: (_) => CreateCompanyPostPage(companyId: widget.company.id),
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
                            builder: (_) => CreateCompanyPage(company: widget.company),
                          ),
                        );
                        if (updated != null && mounted) {
                          Navigator.pop(context); // Return to previous to refresh list
                        }
                      } else if (value == 'delete') {
                        final provider = context.read<CompanyProvider>();
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Company'),
                            content: const Text('Are you sure you want to delete this company?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final success = await provider.deleteCompany(widget.company.id);
                          if (success && mounted) {
                            Navigator.pop(context);
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Company')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Company', style: TextStyle(color: Colors.red))),
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
                            color: Colors.black.withOpacity(0.3),
                            colorBlendMode: BlendMode.darken,
                          )
                        : Container(color: colorScheme.primary.withOpacity(0.8)),
                    
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
                              border: Border.all(color: colorScheme.surface, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
                              ],
                            ),
                            child: ClipOval(
                              child: widget.company.logo != null
                                  ? CachedNetworkImage(
                                      imageUrl: widget.company.logo!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.business, size: 40, color: Colors.grey),
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
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                  indicatorColor: colorScheme.primary,
                  tabs: const [
                    Tab(text: "Posts"),
                    Tab(text: "About"),
                  ],
                ),
                colorScheme.surface,
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
    return FutureBuilder<List<CompanyPost>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading posts."));
        }
        
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No posts yet.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        if (canManage)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateCompanyPostPage(companyId: widget.company.id, post: post),
                                  ),
                                );
                                if (updated == true && mounted) setState(() => _loadPosts());
                              } else if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Post'),
                                    content: const Text('Are you sure you want to delete this post?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true && mounted) {
                                  final success = await context.read<CompanyProvider>().deleteCompanyPost(post.id);
                                  if (success) setState(() => _loadPosts());
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit Post')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete Post', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(post.content),
                    if (post.media.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: post.media.first.file,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAboutTab(TextTheme textTheme, ColorScheme colorScheme) {
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
          const SizedBox(height: 16),
          _buildDetailRow(Icons.language, "Website", widget.company.website, colorScheme),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on, "Location", widget.company.location, colorScheme),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.people, "Company Size", "${widget.company.members.length} members", colorScheme),
          
          const SizedBox(height: 32),
          _buildSectionTitle(textTheme, "Team Members"),
          //const SizedBox(height: 16),
          if (widget.company.members.isEmpty)
            const Text("No members available")
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.company.members.length,
              itemBuilder: (context, index) {
                final member = widget.company.members[index];
                final name = member.user?.fullName ?? member.userString ?? 'Unknown';
                final imageUrl = member.user?.profileImage;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
                    child: imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(member.role, style: TextStyle(color: colorScheme.primary)),
                );
              },
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

  Widget _buildDetailRow(IconData icon, String label, String value, ColorScheme color) {
    return Row(
      children: [
        Icon(icon, color: color.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _color;

  _SliverAppBarDelegate(this._tabBar, this._color);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _color,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
