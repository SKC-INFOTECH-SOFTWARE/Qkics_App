import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/document_provider.dart';
import 'dart:io';

class UploadDocumentPage extends StatefulWidget {
  const UploadDocumentPage({super.key});

  @override
  State<UploadDocumentPage> createState() => _UploadDocumentPageState();
}

class _UploadDocumentPageState extends State<UploadDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _accessType = 'FREE';
  File? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a PDF file")));
      return;
    }

    setState(() => _isUploading = true);
    try {
      await context.read<DocumentProvider>().uploadDocument(
        title: _titleController.text,
        description: _descriptionController.text,
        filePath: _selectedFile!.path,
        accessType: "FREE", // For now, default to FREE until we implement access levels
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document uploaded successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Upload Document",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Share Knowledge",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Upload high-quality notes and documents to help the community grow.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // File Picker
              _buildFilePicker(theme),

              const SizedBox(height: 32),

              _buildTextField(
                controller: _titleController,
                label: "Title",
                hint: "E.g., Advanced Flutter Patterns",
                icon: Icons.title,
              ),
              const SizedBox(height: 24),

              _buildTextField(
                controller: _descriptionController,
                label: "Description",
                hint: "Provide a brief overview of the document contents...",
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Text(
              //   "Access Level",
              //   style: GoogleFonts.inter(
              //     fontWeight: FontWeight.bold,
              //     fontSize: 16,
              //     color: theme.colorScheme.onSurface,
              //   ),
              // ),
              // const SizedBox(height: 12),
              // _buildAccessSelector(theme),

              // const SizedBox(height: 48),

              _buildUploadButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(ThemeData theme) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: _selectedFile != null
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _selectedFile != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedFile != null
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedFile != null
                    ? Icons.picture_as_pdf_rounded
                    : Icons.cloud_upload_outlined,
                size: 36,
                color: _selectedFile != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile != null
                  ? _selectedFile!.path.split('/').last
                  : "Drag and drop or tap to select PDF",
              style: GoogleFonts.inter(
                color: _selectedFile != null
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: _selectedFile != null
                    ? FontWeight.bold
                    : FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_selectedFile == null) ...[
              const SizedBox(height: 4),
              Text(
                "PDF only, max 20MB",
                style: GoogleFonts.inter(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? "This field is required" : null,
        ),
      ],
    );
  }

  Widget _buildAccessSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _SelectableChip(
            label: "Free",
            icon: Icons.lock_open_rounded,
            isSelected: _accessType == 'FREE',
            onTap: () => setState(() => _accessType = 'FREE'),
          ),
          const SizedBox(width: 12),
          _SelectableChip(
            label: "Premium",
            icon: Icons.star_rounded,
            isSelected: _accessType == 'PREMIUM',
            onTap: () => setState(() => _accessType = 'PREMIUM'),
          ),
          const SizedBox(width: 12),
          _SelectableChip(
            label: "Paid",
            icon: Icons.payments_rounded,
            isSelected: _accessType == 'PAID',
            onTap: () => setState(() => _accessType = 'PAID'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isUploading ? null : _handleUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isUploading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                "Upload Document",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
