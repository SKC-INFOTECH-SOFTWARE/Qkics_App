import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../models/document_model.dart';
import 'pdf_viewer_page.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../subscriptions/ui/subscription_plans_page.dart';

class DocumentDetailSheet extends StatefulWidget {
  final Document document;

  const DocumentDetailSheet({super.key, required this.document});

  @override
  State<DocumentDetailSheet> createState() => _DocumentDetailSheetState();
}

class _DocumentDetailSheetState extends State<DocumentDetailSheet> {
  bool _isLoadingDetail = false;
  bool _isDownloading = false;
  Document? _detailedDoc;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.document.file != null) {
      setState(() => _detailedDoc = widget.document);
      return;
    }

    setState(() => _isLoadingDetail = true);
    try {
      final doc = await context.read<DocumentProvider>().fetchDocumentDetail(
        widget.document.uuid,
      );
      if (mounted) {
        setState(() {
          _detailedDoc = doc;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _handleDownload() async {
    final doc = _detailedDoc ?? widget.document;
    final provider = context.read<DocumentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDownloading = true);

    try {
      final path = await provider.downloadDocument(doc);
      if (mounted && path != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Downloaded: ${path.split('/').last}"),
            action: SnackBarAction(
              label: "View",
              onPressed: () => _viewLocalFile(path, doc.title),
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _viewLocalFile(String path, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(filePath: path, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = _detailedDoc ?? widget.document;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  doc.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (doc.accessType == "PREMIUM")
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "PREMIUM",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            doc.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildActionButton(theme, doc),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, Document doc) {
    final subProvider = context.watch<SubscriptionProvider>();
    final hasActiveSub = subProvider.activeSubscription != null;
    final isPremiumDoc = doc.accessType == "PREMIUM";

    if (isPremiumDoc && !hasActiveSub) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
            );
          },
          icon: const Icon(Icons.star, color: Colors.amber),
          label: const Text("Upgrade to Premium"),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    final busy = _isLoadingDetail || _isDownloading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: busy ? null : _handleDownload,
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download),
        label: Text(
          _isLoadingDetail
              ? "Loading…"
              : _isDownloading
                  ? "Downloading…"
                  : "Download Document",
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
