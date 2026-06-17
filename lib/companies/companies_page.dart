import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/models/company.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/companies/create_company_page.dart';
import 'package:q_kics/companies/company_details_page.dart';
import 'package:q_kics/companies/company_posts_page.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Companies",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateCompanyPage(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: "Public"),
            Tab(text: "My Companies"),
            Tab(text: "Posts"),
          ],
        ),
      ),
      body: Consumer<CompanyProvider>(
        builder: (context, companyProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Public Companies
              _buildCompanyList(
                companies: companyProvider.publicCompanies,
                isLoading: companyProvider.isLoadingPublicCompanies,
                onRefresh: companyProvider.fetchCompanyList,
                emptyMessage: "No public companies found.",
              ),
              // My Companies
              _buildCompanyList(
                companies: companyProvider.myCompanies,
                isLoading: companyProvider.isLoadingMyCompanies,
                onRefresh: companyProvider.fetchMyCompanies,
                emptyMessage: "You don't belong to any company.",
              ),
              // Posts feed
              const CompanyPostsPage(),
            ],
          );
        },
      ),
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
