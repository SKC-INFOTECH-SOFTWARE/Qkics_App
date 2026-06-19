// lib/screens/create_post_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/models/post.dart';
import 'package:q_kics/models/tag.dart';
import 'package:q_kics/providers/navigation_provider.dart';
import 'package:q_kics/home/image_ratio_selector_sheet.dart';

class CreatePostPage extends StatefulWidget {
  final Post? postToEdit;
  final ValueChanged<bool>? onBarsVisibilityChanged;

  /// Pre-selects the "Knowledge Hub" option when creating a new post (e.g. when
  /// opened from the Knowledge Hub).
  final bool initialKnowledgeHub;

  const CreatePostPage({
    super.key,
    this.postToEdit,
    this.onBarsVisibilityChanged,
    this.initialKnowledgeHub = false,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final List<File> _mediaFiles = [];
  final List<PostMedia> _existingMedia = [];
  final List<int> _mediaToRemove = [];

  final Set<String> _selectedTags = {};
  List<Tag> _availableTags = [];
  bool _isLoadingTags = true;
  bool _isPosting = false;
  bool _showAllTags = false;
  bool _isKnowledgeHub = false;

  late final bool _isEditMode;
  int? _prevNavIndex;

  static const int titleLimit = 200;
  static const int contentLimit = 10000;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.postToEdit != null;
    if (_isEditMode) {
      _loadExistingPost();
    } else {
      _isKnowledgeHub = widget.initialKnowledgeHub;
    }
    _loadTags();

    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  void _loadExistingPost() {
    final post = widget.postToEdit!;
    _titleController.text = post.title ?? '';
    _contentController.text = post.fullContent ?? post.content;
    _existingMedia.addAll(post.media);
    _selectedTags.addAll(post.tags.map((t) => t.name));
    _isKnowledgeHub = post.knowledgeHub;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nav = context.watch<NavigationProvider>();

    // Only reset when the user navigates TO this tab from another tab.
    // Without this guard, _resetForm fires on every NavigationProvider
    // notification while already on tab 2 (e.g. returning from image picker).
    if (!_isEditMode && nav.index == 2 && _prevNavIndex != null && _prevNavIndex != 2) {
      _resetForm();
    }
    _prevNavIndex = nav.index;
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();

    _selectedTags.clear();
    _mediaFiles.clear();
    _existingMedia.clear();
    _mediaToRemove.clear();
    _showAllTags = false;
    _isKnowledgeHub = false;

    setState(() {});
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

  Future<void> _pickMedia(bool isVideo) async {
    if (_mediaFiles.length + _existingMedia.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 10 media files allowed")),
      );
      return;
    }

    final picker = ImagePicker();
    if (isVideo) {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() {
          _mediaFiles.add(File(picked.path));
        });
      }
    } else {
      final picked = await picker.pickMultiImage(
        imageQuality: 90,
        maxWidth: 1440,
        maxHeight: 1440,
      );
      if (picked.isNotEmpty && mounted) {
        final remaining = 10 - (_mediaFiles.length + _existingMedia.length);
        final files = picked.take(remaining).map((p) => File(p.path)).toList();

        // Show Instagram-style ratio selector before adding to the post
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
          setState(() => _mediaFiles.addAll(croppedFiles));
        }
      }
    }
  }

  void _removeNewMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
  }

  void _removeExistingMedia(int index) {
    setState(() {
      _mediaToRemove.add(_existingMedia[index].id);
      _existingMedia.removeAt(index);
    });
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

  // Removed _removeImage as it is replaced by granular removal

  Future<void> _submitPost() async {
    final fullContent = _contentController.text.trim();

    if (fullContent.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please write something")));
      return;
    }

    final previewContent = fullContent.length > 500
        ? fullContent.substring(0, 500)
        : fullContent;

    setState(() => _isPosting = true);

    final api = context.read<ApiProvider>();
    final nav = context.read<NavigationProvider>();

    try {
      bool success;
      if (_isEditMode) {
        success = await api.updatePost(
          postId: widget.postToEdit!.id,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          previewContent: previewContent,
          fullContent: fullContent,
          mediaFiles: _mediaFiles,
          knowledgeHub: _isKnowledgeHub,
          removeMediaIds: _mediaToRemove.isNotEmpty ? _mediaToRemove : null,
          tags: _selectedTags.toList(),
        );
      } else {
        success = await api.createPost(
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          previewContent: previewContent,
          fullContent: fullContent,
          mediaFiles: _mediaFiles,
          knowledgeHub: _isKnowledgeHub,
          tags: _selectedTags.toList(),
        );
      }

      if (!mounted) return;

      if (success) {
        // 🔥 Clear form first
        _resetForm();

        // 🔥 Refresh posts
        Future.microtask(() {
          api.fetchPosts(forceRefresh: true);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? "Post Updated Successfully!"
                  : "Posted Successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Presented as a pushed route — return to where we came from.
        // Fall back to the Home tab if there's nothing to pop.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          nav.goHome();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? "Failed to update post" : "Failed to create post",
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? "Update failed" : "Post failed"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
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
        // When used as a tab (index 2 in IndexedStack) there is no route to
        // pop, so suppress the auto back button. In edit mode it is pushed
        // as a proper route and the back button should appear.
        automaticallyImplyLeading: _isEditMode,
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
                        //color: canPost ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (n) {
          final cb = widget.onBarsVisibilityChanged;
          if (cb == null) return false;
          if (n.direction == ScrollDirection.reverse) cb(false);
          if (n.direction == ScrollDirection.forward) cb(true);
          return false;
        },
        child: SingleChildScrollView(
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
            const SizedBox(height: 16),

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

            // MEDIA PREVIEW
            if (_mediaFiles.isNotEmpty || _existingMedia.isNotEmpty)
              Container(
                height: 140,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingMedia.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final media = entry.value;
                      return _buildMediaCard(
                        media: media.file,
                        isExisting: true,
                        isVideo: media.mediaType == 'video',
                        onRemove: () => _removeExistingMedia(idx),
                      );
                    }),
                    ..._mediaFiles.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final file = entry.value;
                      return _buildMediaCard(
                        file: file,
                        isExisting: false,
                        isVideo:
                            file.path.toLowerCase().endsWith('.mp4') ||
                            file.path.toLowerCase().endsWith('.mov'),
                        onRemove: () => _removeNewMedia(idx),
                      );
                    }),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickMedia(false),
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
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickMedia(true),
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
            const SizedBox(height: 20),

            // KNOWLEDGE HUB TOGGLE
            SwitchListTile(
              title: const Text(
                "Knowledge Hub",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Make this post available in the Knowledge Hub",
              ),
              value: _isKnowledgeHub,
              onChanged: (val) => setState(() => _isKnowledgeHub = val),
              secondary: Icon(
                Icons.lightbulb_outline,
                color: _isKnowledgeHub ? colorScheme.primary : Colors.grey,
              ),
              contentPadding: EdgeInsets.zero,
              activeColor: colorScheme.primary,
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
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
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
                            selectedColor: colorScheme.primary.withValues(
                              alpha: 0.25,
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
        ), // SingleChildScrollView
      ),   // NotificationListener
    );
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
                    errorWidget: (c, s, e) => const Icon(Icons.error),
                  )
                : isVideo
                ? const Center(
                    child: Icon(Icons.videocam, color: Colors.white, size: 40),
                  )
                : Image.file(file!, width: 120, height: 140, fit: BoxFit.cover),
          ),
          if (isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white70,
                size: 32,
              ),
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
}
