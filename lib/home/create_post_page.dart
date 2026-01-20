// lib/screens/create_post_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/models/tag.dart';

class CreatePostPage extends StatefulWidget {
  final Post? postToEdit;
  const CreatePostPage({super.key, this.postToEdit});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  File? _imageFile;
  String? _existingImageUrl;
  bool _shouldRemoveImage = false;

  final Set<String> _selectedTags = {};
  List<Tag> _availableTags = [];
  bool _isLoadingTags = true;
  bool _isPosting = false;
  bool _showAllTags = false;

  late final bool _isEditMode;

  static const int titleLimit = 200;
  static const int contentLimit = 10000;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.postToEdit != null;
    if (_isEditMode) _loadExistingPost();
    _loadTags();

    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  void _loadExistingPost() {
    final post = widget.postToEdit!;
    _titleController.text = post.title ?? '';
    _contentController.text = post.fullContent ?? post.content;
    _existingImageUrl = post.image;
    _selectedTags.addAll(post.tags.map((t) => t.name));
  }

  Future<void> _loadTags() async {
    setState(() => _isLoadingTags = true);
    final api = Provider.of<ApiProvider>(context, listen: false);
    try {
      final tags = await api.fetchAllTags();
      if (mounted) {
        setState(() {
          _availableTags = tags;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTags = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load tags")));
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() {
        _imageFile = File(picked.path);
        _existingImageUrl = null;
        _shouldRemoveImage = false;
      });
    }
  }

  void _toggleTag(String tagName) {
    setState(() {
      if (_selectedTags.contains(tagName)) {
        _selectedTags.remove(tagName);
      } else if (_selectedTags.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Maximum 5 tags allowed"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _selectedTags.add(tagName);
      }
    });
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _existingImageUrl = null;
      _shouldRemoveImage = true;
    });
  }

  Future<void> _submitPost() async {
    final fullContent = _contentController.text.trim();

    if (fullContent.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please write something")));
      return;
    }

    // Programmatically split content for API
    final previewContent = fullContent.length > 500
        ? fullContent.substring(0, 500)
        : fullContent;

    setState(() => _isPosting = true);
    final api = Provider.of<ApiProvider>(context, listen: false);
    bool success = false;

    try {
      if (_isEditMode) {
        success = await api.updatePost(
          postId: widget.postToEdit!.id,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          previewContent: previewContent,
          fullContent: fullContent,
          image: _imageFile,
          removeImage: _shouldRemoveImage,
          tags: _selectedTags.toList(),
        );
      } else {
        success = await api.createPost(
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          previewContent: previewContent,
          fullContent: fullContent,
          image: _imageFile,
          tags: _selectedTags.toList(),
        );
      }
    } catch (e) {
      debugPrint("Post error: $e");
    }

    setState(() => _isPosting = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? "Post Updated!" : "Posted Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      api.fetchPosts(forceRefresh: true);
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? "Update failed" : "Post failed"),
          backgroundColor: Colors.red,
        ),
      );
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleLength = _titleController.text.length;
    final contentLength = _contentController.text.length;
    final canPost = contentLength > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Post" : "Create Post"),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isPosting || !canPost ? null : _submitPost,
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditMode ? "Update" : "Post",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        //color: canPost ? Colors.white : Colors.white.withOpacity(0.5),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITLE INPUT BOX
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _titleController,
                maxLength: titleLimit,
                decoration: InputDecoration(
                  hintText: "Give your post a title (optional)",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(
                    color: titleLength > titleLimit * 0.9
                        ? Colors.red
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // CONTENT INPUT BOX
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _contentController,
                maxLength: contentLimit,
                minLines: 8,
                maxLines: null,
                decoration: InputDecoration(
                  hintText:
                      "What's on your mind? Share your thoughts, questions, or ideas...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(
                    color: contentLength > contentLimit * 0.9
                        ? Colors.red
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 16, height: 1.6),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),

            // IMAGE PREVIEW
            if (_imageFile != null || _existingImageUrl != null)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 340,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: _imageFile != null
                            ? FileImage(_imageFile!)
                            : CachedNetworkImageProvider(_existingImageUrl!)
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      onPressed: _removeImage,
                      icon: const Icon(
                        Icons.cancel,
                        size: 36,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _imageFile != null || _existingImageUrl != null
                    ? "Change Photo"
                    : "Add Photo",
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TAGS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add Tags (up to 5)",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${_selectedTags.length}/5",
                  style: TextStyle(
                    color: _selectedTags.length >= 5
                        ? Colors.red
                        : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedTags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 0,
                children: _selectedTags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: colorScheme.primary.withOpacity(0.15),
                        deleteIconColor: colorScheme.primary,
                        onDeleted: () => _toggleTag(tag),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),

            _isLoadingTags
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 5,
                    runSpacing: 0,
                    children: _availableTags
                        .take(_showAllTags ? _availableTags.length : 12)
                        .map((tag) {
                          final selected = _selectedTags.contains(tag.name);
                          return FilterChip(
                            label: Text(tag.name),
                            selected: selected,
                            selectedColor: colorScheme.primary.withOpacity(
                              0.25,
                            ),
                            checkmarkColor: colorScheme.primary,
                            onSelected: (_) => _toggleTag(tag.name),
                            avatar: selected
                                ? const Icon(Icons.check, size: 18)
                                : null,
                          );
                        })
                        .toList(),
                  ),

            if (_availableTags.length > 10)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showAllTags = !_showAllTags),
                  child: Text(
                    _showAllTags
                        ? "Show Less"
                        : "Show All Tags (${_availableTags.length})",
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
