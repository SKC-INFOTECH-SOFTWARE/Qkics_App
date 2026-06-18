import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:q_kics/home/image_ratio_selector_sheet.dart';
import 'package:dio/dio.dart';

import 'package:q_kics/models/company_post.dart';
import 'package:q_kics/models/post.dart';

class CreateCompanyPostPage extends StatefulWidget {
  final String companyId;
  final CompanyPost? post;

  const CreateCompanyPostPage({super.key, required this.companyId, this.post});

  @override
  State<CreateCompanyPostPage> createState() => _CreateCompanyPostPageState();
}

class _CreateCompanyPostPageState extends State<CreateCompanyPostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final List<File> _uploadedFiles = [];
  final List<PostMedia> _existingMedia = [];
  bool _isLoading = false;

  bool get isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
      _existingMedia.addAll(widget.post!.media);
    }
  }

  Future<void> _pickImages() async {
    if (_uploadedFiles.length + _existingMedia.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 10 media files allowed")),
      );
      return;
    }

    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 90,
      maxWidth: 1440,
      maxHeight: 1440,
    );
    if (picked.isEmpty || !mounted) return;

    final remaining = 10 - (_uploadedFiles.length + _existingMedia.length);
    final files = picked.take(remaining).map((p) => File(p.path)).toList();

    final croppedFiles = await showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: ImageRatioSelectorSheet(images: files),
      ),
    );

    if (croppedFiles != null && mounted) {
      setState(() => _uploadedFiles.addAll(croppedFiles));
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mov', 'avi', 'mkv', 'webm'],
    );

    final path = result?.files.single.path;
    if (path != null && mounted) {
      setState(() {
        _uploadedFiles.add(File(path));
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and content are required")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'title': title,
        'content': content,
      };

      final provider = context.read<CompanyProvider>();

      if (_uploadedFiles.isNotEmpty) {
        List<MultipartFile> multiFiles = [];
        for (final file in _uploadedFiles) {
          multiFiles.add(await MultipartFile.fromFile(file.path));
        }
        data['uploaded_files'] = multiFiles;
      }

      CompanyPost? postResult;

      if (isEditing) {
        postResult = await provider.updateCompanyPost(widget.post!.id, data);
      } else {
        postResult = await provider.createCompanyPost(widget.companyId, data);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (postResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Post Updated Successfully!'
                    : 'Post Published Successfully!',
              ),
            ),
          );
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate success to parent
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final message = switch (e) {
          CompanyPostPaymentRequiredException(:final price) =>
            'Free posts are finished. Payment required: ${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
          DioException(:final response) =>
            _serverMessage(response?.data),
          _ => 'Something went wrong. Please try again.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Company Post' : 'Create Company Post'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? 'Update' : 'Post',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Post title',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Content field
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _contentController,
                minLines: 6,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "What does your company want to share?",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 16, height: 1.6),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 20),

              if (_existingMedia.isNotEmpty || _uploadedFiles.isNotEmpty) ...[
                Container(
                  height: 140,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._existingMedia.asMap().entries.map((entry) =>
                          _buildMediaCard(
                            media: entry.value.file,
                            isExisting: true,
                            isVideo: entry.value.mediaType == 'video',
                            onRemove: () => setState(
                              () => _existingMedia.removeAt(entry.key),
                            ),
                          )),
                      ..._uploadedFiles.asMap().entries.map((entry) =>
                          _buildMediaCard(
                            file: entry.value,
                            isExisting: false,
                            isVideo: _isVideoFile(entry.value.path),
                            onRemove: () => setState(
                              () => _uploadedFiles.removeAt(entry.key),
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text("Add Photos"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library_outlined),
                      label: const Text("Add Video"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
    );
  }

  String _serverMessage(dynamic data) {
    if (data is Map) {
      // DRF puts the top-level message in 'detail', 'error', or 'message'
      for (final key in ['detail', 'error', 'message']) {
        if (data[key] != null) return data[key].toString();
      }
      // Field-level errors: join the first list of messages found
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.isNotEmpty) return value;
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return 'Something went wrong. Please try again.';
  }

  Widget _buildMediaCard({
    File? file,
    String? media,
    required bool isExisting,
    required bool isVideo,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isExisting
                ? CachedNetworkImage(
                    imageUrl: media!,
                    width: 120,
                    height: 140,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  )
                : isVideo
                ? const SizedBox(
                    width: 120,
                    height: 140,
                    child: Center(
                      child: Icon(Icons.videocam, color: Colors.white, size: 40),
                    ),
                  )
                : Image.file(file!, width: 120, height: 140, fit: BoxFit.cover),
          ),
          if (isVideo)
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 32),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }
}
