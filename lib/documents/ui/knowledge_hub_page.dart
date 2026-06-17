import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/document_provider.dart';
import '../models/document_model.dart';
import '../models/download_history_model.dart';
import 'document_detail_sheet.dart';
import 'pdf_viewer_page.dart';
import 'my_documents_page.dart';

class KnowledgeHubPage extends StatefulWidget {
  final bool embedded;
  final TabController? tabController;

  const KnowledgeHubPage({
    super.key,
    this.embedded = false,
    this.tabController,
  });

  @override
  State<KnowledgeHubPage> createState() => _KnowledgeHubPageState();
}

class _KnowledgeHubPageState extends State<KnowledgeHubPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedAccess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DocumentProvider>();
      provider.fetchDocuments(isActive: true);
      provider.fetchDownloadHistory();
    });
  }

  void _updateFilter(String? type) {
    setState(() => _selectedAccess = type);
    context.read<DocumentProvider>().fetchDocuments(
      isActive: true,
      accessType: type,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();
    final docs = provider.documents;

    final exploreTab = Column(
      children: [
        _buildSearchBar(theme),
        Expanded(
          child: provider.isLoading
              ? _buildShimmer(theme)
              : docs.isEmpty
              ? _buildEmptyState(theme, "No documents available")
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return _DocumentCard(document: doc);
                  },
                ),
        ),
      ],
    );

    final historyTab = provider.isLoadingHistory
        ? _buildShimmer(theme)
        : provider.downloadHistory.isEmpty
        ? _buildEmptyState(theme, "You haven't downloaded any documents yet")
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.downloadHistory.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final history = provider.downloadHistory[index];
              return _HistoryCard(history: history);
            },
          );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: TabBarView(
          controller: widget.tabController,
          children: [exploreTab, historyTab],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyDocumentsPage()),
          ),
          elevation: 4,
          backgroundColor: theme.colorScheme.primary,
          label: Text(
            "My Uploads",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.upload_file),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Document Hub",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorWeight: 3,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: "Explore"),
              Tab(text: "My Downloads"),
            ],
          ),
        ),
        body: TabBarView(children: [exploreTab, historyTab]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyDocumentsPage()),
          ),
          elevation: 4,
          backgroundColor: theme.colorScheme.primary,
          label: Text(
            "My Uploads",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.upload_file),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (val) {
                setState(() => _searchQuery = val);
                context.read<DocumentProvider>().fetchDocuments(
                  search: val,
                  isActive: true,
                  accessType: _selectedAccess,
                );
              },
              decoration: InputDecoration(
                hintText: "Search knowledge base...",
                hintStyle: GoogleFonts.inter(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                          context.read<DocumentProvider>().fetchDocuments(
                            isActive: true,
                            accessType: _selectedAccess,
                          );
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _PremiumChip(
                  label: "All Documents",
                  isSelected: _selectedAccess == null,
                  onSelected: () => _updateFilter(null),
                  icon: Icons.category_outlined,
                ),
                const SizedBox(width: 8),
                _PremiumChip(
                  label: "Free",
                  isSelected: _selectedAccess == "FREE",
                  onSelected: () => _updateFilter("FREE"),
                  icon: Icons.lock_open,
                ),
                const SizedBox(width: 8),
                _PremiumChip(
                  label: "Premium",
                  isSelected: _selectedAccess == "PREMIUM",
                  onSelected: () => _updateFilter("PREMIUM"),
                  icon: Icons.star_outline,
                ),
                const SizedBox(width: 8),
                _PremiumChip(
                  label: "Paid",
                  isSelected: _selectedAccess == "PAID",
                  onSelected: () => _updateFilter("PAID"),
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
      highlightColor: theme.colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _searchQuery.isEmpty ? message : "No results for '$_searchQuery'",
              style: GoogleFonts.inter(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = document.accessType == "PREMIUM";
    final isPaid = document.accessType == "PAID";

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black54,
          builder: (_) => DocumentDetailSheet(document: document),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isPremium || isPaid)
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPremium
                      ? [
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ]
                      : [
                          Colors.blue.withValues(alpha: 0.1),
                          Colors.blue.withValues(alpha: 0.02),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isPremium ? Icons.auto_stories : Icons.article_rounded,
                color: isPremium ? theme.colorScheme.primary : Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPremium || isPaid)
                        _CompactBadge(
                          label: document.accessType,
                          color: isPremium
                              ? theme.colorScheme.primary
                              : Colors.purple,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    document.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CompactBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DownloadHistory history;

  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat(
      'MMM d, yyyy - hh:mm a',
    ).format(history.downloadedAt);

    return InkWell(
      onTap: () async {
        final path = await context.read<DocumentProvider>().getLocalPath(
          history.documentTitle,
        );
        if (path != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PdfViewerPage(filePath: path, title: history.documentTitle),
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("File not found. Please download it again."),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.file_download_done_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.documentTitle,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Downloaded on $date",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData icon;

  const _PremiumChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.icon,
  });

  @override
  State<_PremiumChip> createState() => _PremiumChipState();
}

class _PremiumChipState extends State<_PremiumChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onSelected,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isSelected ? null : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: widget.isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
