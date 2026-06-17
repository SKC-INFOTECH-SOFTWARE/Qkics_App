import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/document_provider.dart';
import '../models/document_model.dart';
import 'upload_document_page.dart';

class MyDocumentsPage extends StatefulWidget {
  const MyDocumentsPage({super.key});

  @override
  State<MyDocumentsPage> createState() => _MyDocumentsPageState();
}

class _MyDocumentsPageState extends State<MyDocumentsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().fetchMyDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Uploads",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadDocumentPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoadingMyDocs
          ? _buildLoadingState(theme)
          : provider.myDocuments.isEmpty
          ? _buildEmptyState(theme)
          : _buildDocumentList(provider.myDocuments, theme),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Loading your documents...",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Uploads Yet",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Share your knowledge with others by uploading your PDFs today.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadDocumentPage()),
              ),
              icon: const Icon(Icons.upload),
              label: const Text("Upload Now"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(List<Document> docs, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _handleMenuAction('change_access', doc),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ModernBadge(
                                label: doc.accessType,
                                color: _getAccessColor(doc.accessType, theme),
                              ),
                              const SizedBox(width: 8),
                              _ModernBadge(
                                label: doc.isActive ? "ACTIVE" : "HIDDEN",
                                color: doc.isActive
                                    ? Colors.green
                                    : Colors.blueGrey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (value) => _handleMenuAction(value, doc),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle_active',
                          child: Row(
                            children: [
                              Icon(
                                doc.isActive
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                doc.isActive
                                    ? "Hide Document"
                                    : "Show Document",
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'change_access',
                          child: Row(
                            children: [
                              Icon(Icons.lock_reset_rounded, size: 20),
                              const SizedBox(width: 12),
                              Text("Change Access"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getAccessColor(String type, ThemeData theme) {
    switch (type) {
      case 'FREE':
        return Colors.blue;
      case 'PREMIUM':
        return theme.colorScheme.primary;
      case 'PAID':
        return Colors.purple;
      default:
        return theme.colorScheme.secondary;
    }
  }

  void _handleMenuAction(String action, Document doc) {
    if (doc.uuid == null) return;

    if (action == 'toggle_active') {
      context.read<DocumentProvider>().updateDocument(
        doc.uuid!,
        isActive: !doc.isActive,
      );
    } else if (action == 'change_access') {
      _showAccessDialog(doc);
    }
  }

  void _showAccessDialog(Document doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Access Level",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['FREE', 'PREMIUM', 'PAID'].map((type) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getAccessColor(
                      type,
                      Theme.of(context),
                    ).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'PREMIUM'
                        ? Icons.star
                        : (type == 'PAID' ? Icons.payments : Icons.lock_open),
                    color: _getAccessColor(type, Theme.of(context)),
                    size: 18,
                  ),
                ),
                title: Text(
                  type,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                trailing: doc.accessType == type
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  context.read<DocumentProvider>().updateDocument(
                    doc.uuid!,
                    accessType: type,
                  );
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ModernBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ModernBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
