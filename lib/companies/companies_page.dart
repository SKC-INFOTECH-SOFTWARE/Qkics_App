import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/models/company.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/companies/create_company_page.dart';
import 'package:q_kics/companies/create_company_post_page.dart';
import 'package:q_kics/companies/company_details_page.dart';
import 'package:q_kics/companies/company_posts_page.dart';

class CompaniesPage extends StatefulWidget {
  final ValueChanged<bool>? onBarsVisibilityChanged;

  const CompaniesPage({super.key, this.onBarsVisibilityChanged});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  // ── Search ────────────────────────────────────────────────
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  static const _tabs = [
    (label: 'Posts', icon: Icons.article_outlined),
    (label: 'Public', icon: Icons.public_outlined),
    (label: 'My Companies', icon: Icons.business_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index != _selectedTab) {
      setState(() => _selectedTab = _tabController.index);
      if (_searchActive && _searchController.text.isNotEmpty) {
        _runSearch(_searchController.text);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _runSearch(query),
    );
  }

  void _runSearch(String query) {
    final q = query.trim().isEmpty ? null : query.trim();
    final provider = context.read<CompanyProvider>();
    switch (_selectedTab) {
      case 0:
        provider.fetchAllCompanyPosts(search: q);
      case 1:
        provider.fetchCompanyList(search: q);
      case 2:
        provider.fetchMyCompanies(search: q);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _searchActive = false);
    final provider = context.read<CompanyProvider>();
    provider.fetchAllCompanyPosts(forceRefresh: true);
    provider.fetchCompanyList();
    provider.fetchMyCompanies();
  }

  void _onAddPressed() {
    if (_selectedTab == 0) {
      // Posts tab — create a company post
      final myCompanies = context.read<CompanyProvider>().myCompanies;
      if (myCompanies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join or create a company to post'),
          ),
        );
        return;
      }
      if (myCompanies.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CreateCompanyPostPage(companyId: myCompanies.first.id),
          ),
        );
      } else {
        _showCompanyPicker(myCompanies);
      }
    } else {
      // Public / My Companies tab — create a company
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateCompanyPage()),
      );
    }
  }

  void _showCompanyPicker(List<Company> companies) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Post as which company?',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...companies.map(
              (company) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      colorScheme.primary.withValues(alpha: 0.12),
                  backgroundImage: company.logo != null
                      ? NetworkImage(company.logo!)
                      : null,
                  child: company.logo == null
                      ? Text(
                          company.name[0].toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(company.name),
                subtitle: Text(
                  company.industry,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CreateCompanyPostPage(companyId: company.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: _selectedTab == 0 ? 'Search posts…' : 'Search companies…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
              )
            : const Text(
                "Companies",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        centerTitle: false,
        actions: [
          _searchActive
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _searchActive = true),
                ),
          if (!_searchActive)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _onAddPressed,
            ),
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (n) {
          final cb = widget.onBarsVisibilityChanged;
          if (cb == null) return false;
          if (n.direction == ScrollDirection.reverse) cb(false);
          if (n.direction == ScrollDirection.forward) cb(true);
          return false;
        },
        child: Column(
        children: [
          // ── Chip tab bar ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final selected = _selectedTab == i;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = i);
                        _tabController.animateTo(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _tabs[i].icon,
                              size: 16,
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tabs[i].label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
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
          ),

          // ── Tab content ───────────────────────────────────
          Expanded(
            child: Consumer<CompanyProvider>(
              builder: (context, companyProvider, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    const CompanyPostsPage(),
                    _buildCompanyList(
                      companies: companyProvider.publicCompanies,
                      isLoading: companyProvider.isLoadingPublicCompanies,
                      onRefresh: companyProvider.fetchCompanyList,
                      emptyMessage: "No public companies found.",
                    ),
                    _buildCompanyList(
                      companies: companyProvider.myCompanies,
                      isLoading: companyProvider.isLoadingMyCompanies,
                      onRefresh: companyProvider.fetchMyCompanies,
                      emptyMessage: "You don't belong to any company.",
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        ), // Column
      ),   // NotificationListener
    );
  }

  Widget _buildCompanyList({
    required List<Company> companies,
    required bool isLoading,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
  }) {
    if (isLoading && companies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (companies.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 16, bottom: 100), // Bottom padding for nav bar
        itemCount: companies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final company = companies[index];
          return _CompanyCard(company: company);
        },
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final Company company;

  const _CompanyCard({Key? key, required this.company}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompanyDetailsPage(company: company),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image wrapper
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 21 / 9,
                  child: company.coverImage != null
                      ? CachedNetworkImage(
                          imageUrl: company.coverImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.business, size: 48, color: Colors.grey),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: company.logo != null
                            ? CachedNetworkImage(
                                imageUrl: company.logo!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: colorScheme.surfaceContainerHighest),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.business, size: 30, color: Colors.grey),
                              )
                            : const Icon(Icons.business, size: 30, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.industry,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            company.description,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        company.location,
                                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.people_outline, size: 14, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        "${company.members.length} members",
                                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }
}
