// lib/widgets/comment_sheet.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/models/comment.dart';

class CommentSheet extends StatefulWidget {
  final int postId;
  const CommentSheet({required this.postId, super.key});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiProvider>(context, listen: false);
    api.setCurrentPostId(widget.postId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      api.fetchComments(widget.postId, forceRefresh: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        final api = Provider.of<ApiProvider>(context, listen: false);
        if (api.hasMoreComments && !api.isLoadingComments) {
          api.fetchComments(widget.postId);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiProvider>(context);
    final comments = api.comments;
    final user = api.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 2,
            width: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "Comments",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),

          // Comments List
          Expanded(
            child: comments.isEmpty && api.isLoadingComments
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        comments.length +
                        (api.hasMoreComments && !api.isLoadingComments ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= comments.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(strokeWidth: 2),
                                SizedBox(height: 12),
                                Text(
                                  "Loading more comments...",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return CommentTile(
                        comment: comments[index],
                        postId: widget.postId,
                        depth: 0,
                        onChanged: () => api.fetchComments(
                          widget.postId,
                          forceRefresh: true,
                        ),
                      );
                    },
                  ),
          ),

          // Input Box — BEAUTIFUL & MULTILINE
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Text(
                    user?.username[0].toUpperCase() ?? "U",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // MAIN COMMENT INPUT — FIXED (now Post button enables instantly)
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      maxLength: 5000,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: InputBorder.none,
                        isDense: true,
                        counterText: "",
                      ),
                      style: const TextStyle(fontSize: 15),
                      onChanged: (value) =>
                          setState(() {}), // ← THIS WAS MISSING!
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _controller.text.trim().isEmpty
                      ? null
                      : () async {
                          final text = _controller.text.trim();
                          final success = await api.addComment(
                            widget.postId,
                            text,
                          );
                          if (success) {
                            _controller.clear();
                            setState(
                              () {},
                            ); // ← Important: clears disabled state
                            api.fetchComments(
                              widget.postId,
                              forceRefresh: true,
                            );
                            FocusScope.of(context).unfocus();
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _controller.text.trim().isEmpty
                          ? Colors.grey[400]
                          : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CommentTile extends StatefulWidget {
  final Comment comment;
  final int postId;
  final int depth;
  final VoidCallback onChanged;

  const CommentTile({
    required this.comment,
    required this.postId,
    required this.depth,
    required this.onChanged,
    super.key,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isReplying = false;
  bool _isEditing = false;
  late final TextEditingController _replyController;
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _replyController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _startEdit() {
    if (!mounted) return;
    setState(() {
      _isEditing = true;
      _editController.text = widget.comment.content;
      _editController.selection = TextSelection.fromPosition(
        TextPosition(offset: _editController.text.length),
      );
    });
  }

  void _cancelEdit() {
    if (!mounted) return;
    setState(() {
      _isEditing = false;
      _editController.text = widget.comment.content;
    });
  }

  Future<void> _saveEdit() async {
    final text = _editController.text.trim();
    if (text.isEmpty || text == widget.comment.content) {
      if (mounted) setState(() => _isEditing = false);
      return;
    }
    final api = Provider.of<ApiProvider>(context, listen: false);
    final success = widget.comment.parent == null
        ? await api.updateComment(widget.comment.id, widget.postId, text)
        : await api.updateReply(widget.comment.id, text);
    if (!mounted) return;
    setState(() => _isEditing = false);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOwn = widget.comment.author.id == api.currentUser?.id;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final profilePic = widget.comment.author.profilePicture;
    final hasPic = profilePic != null && profilePic.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: widget.depth * 40.0, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                child: hasPic
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: profilePic!,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                          memCacheWidth:
                              (40 * MediaQuery.of(context).devicePixelRatio)
                                  .toInt(),
                          memCacheHeight:
                              (40 * MediaQuery.of(context).devicePixelRatio)
                                  .toInt(),
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        widget.comment.author.initial,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.comment.author.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeago.format(
                            widget.comment.createdAt,
                            locale: 'en_short',
                          ),
                          style: TextStyle(color: secondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_isEditing)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _editController,
                              autofocus: true,
                              maxLines: null,
                              maxLength: 5000,
                              style: TextStyle(color: textColor),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Edit your comment...",
                                counterText: "",
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _cancelEdit,
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: _saveEdit,
                                  child: const Text("Save"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        widget.comment.content,
                        style: const TextStyle(fontSize: 14.5, height: 1.5),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              _isReplying = true;
                              _replyController.text =
                                  "@${widget.comment.author.username} ";
                            });
                          },
                          child: Text(
                            "Reply",
                            style: TextStyle(
                              color: secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () async {
                            if (!mounted) return;
                            setState(() {
                              widget.comment.isLiked = !widget.comment.isLiked;
                              widget.comment.totalLikes +=
                                  widget.comment.isLiked ? 1 : -1;
                            });
                            await api.toggleCommentLike(widget.comment.id);
                          },
                          child: Row(
                            children: [
                              Icon(
                                widget.comment.isLiked
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                color: widget.comment.isLiked
                                    ? Colors.red
                                    : secondary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              if (widget.comment.totalLikes > 0)
                                Text(
                                  "${widget.comment.totalLikes}",
                                  style: TextStyle(
                                    color: widget.comment.isLiked
                                        ? Colors.red
                                        : secondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwn && !_isEditing)
                PopupMenuButton(
                  icon: Icon(Icons.more_horiz, color: secondary),
                  onSelected: (v) => v == 'edit'
                      ? _startEdit()
                      : api
                            .deleteComment(widget.comment.id, widget.postId)
                            .then((_) => widget.onChanged()),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text("Edit")),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // REPLY BOX — BEAUTIFUL MULTILINE
          if (_isReplying)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 56),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    child: Text(
                      api.currentUser?.username[0].toUpperCase() ?? "U",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 55),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: TextField(
                        controller: _replyController,
                        maxLines: null,
                        maxLength: 5000,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "Write a reply...",
                          border: InputBorder.none,
                          counterText: "",
                        ),
                        onChanged: (_) => setState(() {}), // ← CRITICAL FIX
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _replyController.text.trim().isEmpty
                        ? null
                        : () async {
                            final text = _replyController.text.trim();
                            final int correctId = api.comments
                                .firstWhere(
                                  (c) =>
                                      c.id == widget.comment.id ||
                                      c.replies.any(
                                        (r) => r.id == widget.comment.id,
                                      ) ||
                                      c.replies
                                          .expand((r) => r.replies)
                                          .any(
                                            (r) => r.id == widget.comment.id,
                                          ),
                                  orElse: () => widget.comment,
                                )
                                .id;

                            final success = await api.addReply(correctId, text);
                            if (!mounted) return;
                            if (success) {
                              _replyController.clear();
                              setState(() => _isReplying = false);
                              widget.onChanged();
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _replyController.text.trim().isEmpty
                            ? Colors.grey[400]
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // VIEW REPLIES — SHOWS NUMBER
          if (widget.comment.parent == null &&
              widget.comment.totalReplies > 0 &&
              widget.comment.replies.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 56),
              child: GestureDetector(
                onTap: () => api.fetchReplies(widget.comment.id),
                child: Text(
                  "View ${widget.comment.totalReplies} ${widget.comment.totalReplies == 1 ? 'reply' : 'replies'}",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // NESTED REPLIES
          ...widget.comment.replies.map(
            (r) => CommentTile(
              comment: r,
              postId: widget.postId,
              depth: widget.depth + 1,
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
