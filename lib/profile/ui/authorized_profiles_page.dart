import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/providers/authorized_profiles_provider.dart';
import 'package:q_kics/profile/models/expert/expert_profile_model.dart';
import 'package:q_kics/profile/models/entrepreneur/entrepreneur_profile_model.dart';
import 'package:q_kics/profile/models/investor/investor_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/profile/ui/widgets/public/public_profile_page.dart';
import 'package:q_kics/booking/investor_slots_page.dart';

class AuthorizedProfilesPage extends StatefulWidget {
  final bool onlyInvestors;
  const AuthorizedProfilesPage({super.key, this.onlyInvestors = false});

  @override
  State<AuthorizedProfilesPage> createState() => _AuthorizedProfilesPageState();
}

class _AuthorizedProfilesPageState extends State<AuthorizedProfilesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Search state ──────────────────────────────────────────
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.onlyInvestors) _tabController.index = 2;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(query));
  }

  void _runSearch(String query) {
    final provider = context.read<AuthorizedProfilesProvider>();
    final q = query.trim().isEmpty ? null : query.trim();
    if (widget.onlyInvestors) {
      provider.fetchInvestors(search: q);
      return;
    }
    // Search only the active tab to avoid 3 parallel heavy requests
    switch (_tabController.index) {
      case 0:
        provider.fetchExperts(search: q);
      case 1:
        provider.fetchEntrepreneurs(search: q);
      case 2:
        provider.fetchInvestors(search: q);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _searchActive = false);
    // Reload full list
    final provider = context.read<AuthorizedProfilesProvider>();
    if (widget.onlyInvestors) {
      provider.fetchInvestors();
    } else {
      provider.fetchAll();
    }
  }

  void _openPublicProfile(String username) {
    if (username.isEmpty) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfilePage(username: username)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AuthorizedProfilesProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        title: _searchActive
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: MediaQuery.of(context).size.width >= 600 ? 20 : 16,
                ),
              )
            : Text(
                widget.onlyInvestors ? "Investor Linkup" : "Authorized Profiles",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width >= 600 ? 24 : 20,
                ),
              ),
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
        ],
        bottom: widget.onlyInvestors
            ? null
            : TabBar(
                controller: _tabController,
                onTap: (_) {
                  // Re-run search when switching tabs so results match
                  if (_searchActive && _searchController.text.isNotEmpty) {
                    _runSearch(_searchController.text);
                  }
                },
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width >= 600 ? 16 : 13,
                ),
                tabs: const [
                  Tab(text: "Experts"),
                  Tab(text: "Entrepreneurs"),
                  Tab(text: "Investors"),
                ],
              ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(child: Text("Error: ${provider.error}"))
          : widget.onlyInvestors
          ? _buildInvestorList(provider.investors)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExpertList(provider.experts),
                _buildEntrepreneurList(provider.entrepreneurs),
                _buildInvestorList(provider.investors),
              ],
            ),
    );
  }

  Widget _buildExpertList(List<ExpertProfile> list) {
    if (list.isEmpty) return const _EmptyState(message: "No experts found");
    return _buildResponsiveList(
      itemCount: list.length,
      itemBuilder: (context, i) => _ExpertHorizontalCard(
        expert: list[i],
        onTap: () => _openPublicProfile(list[i].username),
      ),
    );
  }

  Widget _buildEntrepreneurList(List<EntrepreneurProfile> list) {
    if (list.isEmpty) {
      return const _EmptyState(message: "No entrepreneurs found");
    }
    return _buildResponsiveList(
      itemCount: list.length,
      itemBuilder: (context, i) => _EntrepreneurHorizontalCard(
        entrepreneur: list[i],
        onTap: () => _openPublicProfile(list[i].username),
      ),
    );
  }

  Widget _buildInvestorList(List<InvestorProfile> list) {
    if (list.isEmpty) return const _EmptyState(message: "No investors found");
    return _buildResponsiveList(
      itemCount: list.length,
      itemBuilder: (context, i) => _InvestorHorizontalCard(
        investor: list[i],
        onTap: () => _openPublicProfile(list[i].username),
        onBookTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvestorSlotsPage(
              investorUuid: list[i].uuid,
              investorName: list[i].displayName,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final isLargeTablet = width >= 900;

    final double padding = isLargeTablet
        ? 30
        : isTablet
        ? 24
        : 12;

    int crossAxisCount = 1;
    double aspectRatio = 4.2;

    if (isLargeTablet) {
      crossAxisCount = 2;
      aspectRatio = 2.6; // More vertical space
    } else if (isTablet) {
      crossAxisCount = 2;
      aspectRatio = 2.6; // Even more vertical space for 2-column layout
    }

    if (crossAxisCount == 1) {
      return ListView.separated(
        padding: EdgeInsets.all(padding),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: isTablet ? 20 : 12),
        itemBuilder: itemBuilder,
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: isTablet ? 24 : 16,
        crossAxisSpacing: isTablet ? 24 : 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: isTablet ? 96 : 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(color: Colors.grey, fontSize: isTablet ? 22 : 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CARDS
// ──────────────────────────────────────────────────────────────────────────────

class _ExpertHorizontalCard extends StatelessWidget {
  final ExpertProfile expert;
  final VoidCallback onTap;

  const _ExpertHorizontalCard({required this.expert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return _BaseHorizontalCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: isTablet ? 20 : 12,
        children: [
          _Avatar(imageUrl: expert.profilePicture, name: expert.firstName),
          SizedBox(width: isTablet ? 0 : 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TitleRow(
                  title: "${expert.firstName} ${expert.lastName}",
                  // verified: expert.verified,
                ),
                SizedBox(height: isTablet ? 6 : 2),
                _PrimaryText(expert.primaryExpertise),
                if (expert.headline.isNotEmpty) ...[
                  SizedBox(height: isTablet ? 6 : 4),
                  _SecondaryText(expert.headline),
                ],
              ],
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Flexible(child: _PriceChip("₹${expert.hourlyRate}/hr")),
        ],
      ),
    );
  }
}

class _EntrepreneurHorizontalCard extends StatelessWidget {
  final EntrepreneurProfile entrepreneur;
  final VoidCallback onTap;

  const _EntrepreneurHorizontalCard({
    required this.entrepreneur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return _BaseHorizontalCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            imageUrl: entrepreneur.profilePicture,
            name: entrepreneur.startupName,
          ),
          SizedBox(width: isTablet ? 20 : 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TitleRow(title: entrepreneur.startupName),
                SizedBox(height: isTablet ? 6 : 2),
                _PrimaryText(entrepreneur.industry),
                if (entrepreneur.oneLiner.isNotEmpty) ...[
                  SizedBox(height: isTablet ? 6 : 4),
                  _SecondaryText(entrepreneur.oneLiner),
                ],
              ],
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Flexible(
            child: _TagChip(
              entrepreneur.fundingStage.toUpperCase(),
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestorHorizontalCard extends StatelessWidget {
  final InvestorProfile investor;
  final VoidCallback onTap;
  final VoidCallback onBookTap;

  const _InvestorHorizontalCard({
    required this.investor,
    required this.onTap,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return _BaseHorizontalCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            imageUrl: investor.profilePicture,
            name: investor.displayName,
          ),
          SizedBox(width: isTablet ? 20 : 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TitleRow(
                  title: investor.displayName,
                  verified: investor.verifiedByAdmin,
                ),
                if (investor.investorTypeDisplay.isNotEmpty) ...[
                  SizedBox(height: isTablet ? 6 : 2),
                  _PrimaryText(investor.investorTypeDisplay),
                ],
                if (investor.location.isNotEmpty) ...[
                  SizedBox(height: isTablet ? 6 : 4),
                  _SecondaryText(investor.location),
                ],
              ],
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _PriceChip(
                "₹${investor.checkSizeMin.toStringAsFixed(0)} - ₹${investor.checkSizeMax.toStringAsFixed(0)}",
                small: true,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onBookTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Book",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SHARED COMPONENTS
// ──────────────────────────────────────────────────────────────────────────────

class _BaseHorizontalCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BaseHorizontalCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Material(
      color: cs.surface,
      elevation: isTablet ? 6 : 3, // 🔥 stronger elevation
      shadowColor: cs.primary.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.22), // 🎨 colored border
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String title;
  final bool verified;

  const _TitleRow({required this.title, this.verified = false});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isTablet ? 20 : 14,
            ),
          ),
        ),
        if (verified)
          Padding(
            padding: EdgeInsets.only(left: isTablet ? 8 : 4),
            child: Icon(
              Icons.verified,
              size: isTablet ? 24 : 18,
              color: Colors.blue,
            ),
          ),
      ],
    );
  }
}

class _PrimaryText extends StatelessWidget {
  final String text;

  const _PrimaryText(this.text);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: isTablet ? 17 : 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SecondaryText extends StatelessWidget {
  final String text;

  const _SecondaryText(this.text);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Text(
      text,
      maxLines: isTablet ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isTablet ? 15 : 12,
        height: 1.3,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String text;
  final bool small;

  const _PriceChip(this.text, {this.small = false});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: small ? (isTablet ? 6 : 5) : (isTablet ? 8 : 7),
      ),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.primary,
          fontSize: isTablet ? (small ? 14 : 16) : (small ? 12 : 14),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color color;

  const _TagChip(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: isTablet ? 15 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _Avatar({this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final isLargeTablet = width >= 900;

    final double size = isLargeTablet
        ? 110
        : isTablet
        ? 96
        : 64;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(isTablet ? 4 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
          width: isTablet ? 2.5 : 1.5,
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: (size * MediaQuery.of(context).devicePixelRatio)
                    .toInt(),
                memCacheHeight: (size * MediaQuery.of(context).devicePixelRatio)
                    .toInt(),
                errorWidget: (_, __, ___) => _AvatarFallback(name: name),
              )
            : _AvatarFallback(name: name),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;

  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: isTablet ? 38 : 26,
        ),
      ),
    );
  }
}
