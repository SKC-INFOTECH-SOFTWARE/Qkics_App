import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/chat/models/chat_room.dart';
import 'package:q_kics/chat/models/chat_message.dart';
import 'package:q_kics/providers/chat_provider.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:intl/intl.dart';
import 'package:q_kics/chat/widgets/typing_indicator.dart';

class ChatMessagesPage extends StatefulWidget {
  final ChatRoom room;
  const ChatMessagesPage({super.key, required this.room});

  @override
  State<ChatMessagesPage> createState() => _ChatMessagesPageState();
}

class _ChatMessagesPageState extends State<ChatMessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  int _prevMessageCount = 0;
  bool _hasInitialScrolled = false;
  bool _showScrollToBottom = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<ChatProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiProv = context.read<ApiProvider>();
      final chatProv = context.read<ChatProvider>();

      chatProv.fetchChatMessages(widget.room.id);

      final token = apiProv.accessToken;
      final user = apiProv.currentUser;

      if (token != null && user != null) {
        chatProv.connectToRoom(widget.room.id, token, user.username, user.id);
      }
    });

    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onMessageChanged);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Show button if we are more than 300 pixels away from the bottom
    final show = (maxScroll - currentScroll) > 300;

    if (show != _showScrollToBottom) {
      if (mounted) {
        setState(() {
          _showScrollToBottom = show;
        });
      }
    }
  }

  bool _isTyping = false;
  Timer? _typingTimer;

  void _onMessageChanged() {
    final text = _messageController.text.trim();

    // If text is not empty
    if (text.isNotEmpty) {
      // If we weren't typing before, send "true" once
      if (!_isTyping) {
        _isTyping = true;
        context.read<ChatProvider>().sendTyping(true);
      }

      // Debounce: Cancel previous timer and start a new one
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(milliseconds: 2000), () {
        // If 2 seconds passed without typing, we assume stopped
        if (_isTyping) {
          _isTyping = false;
          // Check mounted to be safe, though context.read is usually fine
          if (mounted) context.read<ChatProvider>().sendTyping(false);
        }
      });
    } else {
      // If text became empty explicitly (user cleared it), send stop immediately
      _typingTimer?.cancel();
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatProvider>().sendTyping(false);
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _chatProvider.disconnectFromRoom(notify: false);
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final success = await context.read<ChatProvider>().sendMessage(
      widget.room.id,
      text,
    );

    if (success) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomStrict() {
    if (_scrollController.hasClients) {
      // Check if user is near bottom or if it's the first load (roughly)
      // For now, always scroll significantly to ensure visibility of new items
      // unless user is way up. But standard "WhatsApp" behavior:
      // If I sent it -> always scroll (handled by _sendMessage)
      // If received -> scroll only if already at bottom.

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      // Threadshold: 200px from bottom
      if ((maxScroll - currentScroll) <= 200) {
        _scrollController.animateTo(
          maxScroll + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<ApiProvider>().currentUser;
    final otherUser = widget.room.user.id == currentUser?.id
        ? widget.room.advisor
        : widget.room.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: otherUser.profileImage != null
                  ? NetworkImage(otherUser.profileImage!)
                  : null,
              child: otherUser.profileImage == null
                  ? Text(
                      otherUser.initials,
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUser.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<ChatProvider>(
                  builder: (context, cp, _) {
                    final isTyping = cp.isOtherTyping;
                    final isOnline = cp.onlineUsers.contains(otherUser.id);

                    if (isTyping) {
                      return Text(
                        "typing...",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }

                    return Text(
                      isOnline ? "Online" : "Offline",
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green[400] : Colors.grey[400],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProv, child) {
                if (chatProv.isLoadingMessages) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProv.messagesError != null) {
                  return Center(
                    child: Text("Error: ${chatProv.messagesError}"),
                  );
                }

                final messages = chatProv.messages;

                if (messages.length > _prevMessageCount) {
                  // If this is the FIRST load (or re-load from empty), jump to bottom
                  if (!_hasInitialScrolled && messages.isNotEmpty) {
                    _prevMessageCount = messages.length;
                    _hasInitialScrolled = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });
                  } else {
                    // Normal new message
                    _prevMessageCount = messages.length;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottomStrict();
                    });
                  }
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          // Mark as read if it's not mine and seen
                          if (!message.isMine && !message.isRead) {
                            chatProv.markAsRead(message.id);
                          }
                          return _MessageBubble(message: message);
                        },
                      ),
                    ),
                    if (chatProv.isOtherTyping)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          bottom: 8,
                          top: 4,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: const TypingIndicator(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
      floatingActionButton: _showScrollToBottom
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70), // Lift above input
              child: SizedBox(
                height: 35,
                width: 35,
                child: FloatingActionButton(
                  onPressed: _scrollToBottom,
                  backgroundColor: Theme.of(context).primaryColor,
                  mini: true,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {}, // Implementation for file picker can go here
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200]?.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? Theme.of(context).primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMine
                    ? const Radius.circular(16)
                    : const Radius.circular(0),
                bottomRight: isMine
                    ? const Radius.circular(0)
                    : const Radius.circular(16),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: isMine ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              if (isMine) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 16,
                  color: message.isRead ? Colors.blue : Colors.grey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
