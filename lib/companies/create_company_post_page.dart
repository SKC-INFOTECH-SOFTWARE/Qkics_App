import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/providers/company_provider.dart';
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
  final _formKey = GlobalKey<FormState>();
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
    final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty && mounted) {
      setState(() {
        _uploadedFiles.addAll(pickedFiles.map((pf) => File(pf.path)));
      });
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
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
          _ => 'Error: $e',
        };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Company Post' : 'Create Company Post'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Post Title',
                icon: Icons.title,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _contentController,
                label: 'What do you want to share?',
                icon: Icons.article_outlined,
                maxLines: 8,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Content required' : null,
              ),
              const SizedBox(height: 24),

              if (_existingMedia.isNotEmpty || _uploadedFiles.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._existingMedia.map(_buildExistingMediaPreview),
                      ..._uploadedFiles.asMap().entries.map(
                        (entry) =>
                            _buildPickedFilePreview(entry.key, entry.value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text("Add Photos"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: colorScheme.primary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Post' : 'Publish Post',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: maxLines == 1 ? label : null,
        hintText: maxLines > 1 ? label : null,
        prefixIcon: maxLines == 1
            ? Icon(icon, color: theme.colorScheme.primary)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Widget _buildExistingMediaPreview(PostMedia media) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            fit: StackFit.expand,
            children: [
              media.isVideo
                  ? Container(
                      color: Colors.black87,
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: media.file,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
              if (media.isVideo)
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickedFilePreview(int index, File file) {
    final isVideo = _isVideoFile(file.path);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 100,
              height: 100,
              child: isVideo
                  ? Container(
                      color: Colors.black87,
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : Image.file(file, fit: BoxFit.cover),
            ),
          ),
          if (isVideo)
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _uploadedFiles.removeAt(index);
                });
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
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
