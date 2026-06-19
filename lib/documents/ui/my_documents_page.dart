import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/document_provider.dart';
import '../models/document_model.dart';
import 'upload_document_page.dart';
import 'document_detail_sheet.dart';

class MyDocumentsPage extends StatefulWidget {
  /// When true, renders body-only (no Scaffold/AppBar) so it can live inside a
  /// TabBarView; the app-bar upload action becomes an inline button.
  final bool embedded;

  /// Extra bottom padding so the list clears a floating bottom nav bar.
  final double contentBottomInset;

  const MyDocumentsPage({
    super.key,
    this.embedded = false,
    this.contentBottomInset = 0,
  });

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

  void _openUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadDocumentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<DocumentProvider>();

    final content = provider.isLoadingMyDocs
        ? _buildLoadingState(theme)
        : provider.myDocuments.isEmpty
        ? _buildEmptyState(theme)
        : _buildDocumentList(provider.myDocuments, theme);

    if (widget.embedded) {
      return Column(
        children: [
          // Inline upload action (replaces the removed FAB / app-bar button).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _openUpload,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(
                  "Upload PDF",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

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
            onPressed: _openUpload,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + widget.contentBottomInset),
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
              onTap: () => _openDocument(doc),
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
                          _ModernBadge(
                            label: doc.isActive ? "ENABLED" : "DISABLED",
                            color: doc.isActive ? Colors.green : Colors.blueGrey,
                          ),
                        ],
                      ),
                    ),
                    // PopupMenuButton<String>(
                    //   icon: Icon(
                    //     Icons.more_vert_rounded,
                    //     color: theme.colorScheme.onSurfaceVariant,
                    //   ),
                    //   onSelected: (value) {
                    //     if (value == 'edit') {
                    //       _showEditSheet(doc);
                    //     } else {
                    //       _toggleStatus(doc);
                    //     }
                    //   },
                    //   shape: RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(16),
                    //   ),
                    //   itemBuilder: (context) => [
                    //     const PopupMenuItem(
                    //       value: 'edit',
                    //       child: Row(
                    //         children: [
                    //           Icon(Icons.edit_outlined, size: 20),
                    //           SizedBox(width: 12),
                    //           Text("Edit"),
                    //         ],
                    //       ),
                    //     ),
                    //     PopupMenuItem(
                    //       value: 'toggle',
                    //       child: Row(
                    //         children: [
                    //           Icon(
                    //             doc.isActive
                    //                 ? Icons.toggle_off_outlined
                    //                 : Icons.toggle_on_outlined,
                    //             size: 22,
                    //             color: doc.isActive
                    //                 ? Colors.blueGrey
                    //                 : Colors.green,
                    //           ),
                    //           const SizedBox(width: 12),
                    //           Text(doc.isActive ? "Disable" : "Enable"),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDocument(Document doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentDetailSheet(document: doc),
    );
  }

  void _showEditSheet(Document doc) {
    if (doc.uuid == null) return;
    final titleCtrl = TextEditingController(text: doc.title);
    final descCtrl = TextEditingController(text: doc.description);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Document",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Title is required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Description is required"
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final messenger = ScaffoldMessenger.of(context);
                            final provider = context.read<DocumentProvider>();
                            setSheetState(() => saving = true);
                            try {
                              await provider.updateDocument(
                                doc.uuid!,
                                title: titleCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (ctx.mounted) {
                                setSheetState(() => saving = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Save Changes",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(Document doc) async {
    if (doc.uuid == null) return;
    try {
      await context.read<DocumentProvider>().toggleDocument(doc.uuid!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
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
