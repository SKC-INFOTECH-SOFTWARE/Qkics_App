import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<NotificationProvider>()
          .fetchNotifications(forceRefresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.85) {
      context.read<NotificationProvider>().fetchNotifications();
    }
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }

      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _markSelectedAsRead() async {
    final provider = context.read<NotificationProvider>();

    for (final id in _selectedIds) {
      await provider.markAsRead(id);
    }

    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  void _navigate(NotificationModel notification) {
    final event = notification.event;
    final data = notification.data;

    if (event == null) return;

    switch (event) {
      case 'POST_COMMENTED':
      case 'POST_LIKED':
      case 'COMMENT_REPLIED':
        if (data['postId'] != null) {
          Navigator.pushNamed(
            context,
            '/post_detail',
            arguments: data['postId'],
          );
        }
        break;

      case 'BOOKING_CONFIRMED':
      case 'BOOKING_APPROVED':
      case 'BOOKING_DECLINED':
        if (data['bookingId'] != null) {
          Navigator.pushNamed(
            context,
            '/booking_detail',
            arguments: data['bookingId'],
          );
        }
        break;

      case 'NEW_CHAT_MESSAGE':
        if (data['roomId'] != null) {
          Navigator.pushNamed(
            context,
            '/chat_room',
            arguments: data['roomId'],
          );
        }
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: _selectionMode
            ? Text("${_selectedIds.length} selected")
            : const Text(
                "Notifications",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markSelectedAsRead,
            )
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text("No notifications yet"),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                provider.fetchNotifications(forceRefresh: true),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification =
                    provider.notifications[index];

                final isSelected =
                    _selectedIds.contains(notification.id);

                return InkWell(
                  onLongPress: () =>
                      _enterSelectionMode(notification.id),
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(notification.id);
                    } else {
                      provider.markAsRead(notification.id);
                      _navigate(notification);
                    }
                  },
                  child: Container(
                    color: notification.isRead
                        ? Colors.white
                        : const Color(0xFFE7F3FF), // Facebook blue
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary,
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.subject,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.body,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeago.format(
                                    notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectionMode)
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color:
                                theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}