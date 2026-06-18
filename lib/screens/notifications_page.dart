import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationsPage extends StatefulWidget {
  final ValueChanged<bool>? onBarsVisibilityChanged;

  const NotificationsPage({super.key, this.onBarsVisibilityChanged});

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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
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

    if (!mounted) return;
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
          Navigator.pushNamed(context, '/post_detail', arguments: data['postId']);
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
          Navigator.pushNamed(context, '/chat_room', arguments: data['roomId']);
        }
        break;

      default:
        break;
    }
  }

  ({IconData icon, Color color}) _styleForEvent(
    String? event,
    ColorScheme colorScheme,
  ) {
    switch (event) {
      case 'POST_LIKED':
        return (icon: Icons.thumb_up_rounded, color: Colors.red);
      case 'POST_COMMENTED':
      case 'COMMENT_REPLIED':
        return (icon: Icons.mode_comment_rounded, color: colorScheme.primary);
      case 'BOOKING_CONFIRMED':
      case 'BOOKING_APPROVED':
        return (icon: Icons.event_available_rounded, color: Colors.green);
      case 'BOOKING_DECLINED':
        return (icon: Icons.event_busy_rounded, color: Colors.red);
      case 'NEW_CHAT_MESSAGE':
        return (icon: Icons.chat_bubble_rounded, color: colorScheme.tertiary);
      default:
        return (
          icon: Icons.notifications_rounded,
          color: colorScheme.onSurfaceVariant,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
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
              icon: const Icon(Icons.done_all_rounded),
              tooltip: "Mark as read",
              onPressed: _markSelectedAsRead,
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
        child: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.fetchNotifications(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No notifications yet",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(forceRefresh: true),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount:
                  provider.notifications.length + (provider.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 72,
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notification = provider.notifications[index];
                final isSelected = _selectedIds.contains(notification.id);
                final style = _styleForEvent(notification.event, colorScheme);

                return Material(
                  color: notification.isRead
                      ? Colors.transparent
                      : colorScheme.primary.withValues(alpha: 0.06),
                  child: InkWell(
                    onLongPress: () => _enterSelectionMode(notification.id),
                    onTap: () {
                      if (_selectionMode) {
                        _toggleSelection(notification.id);
                      } else {
                        context.read<NotificationProvider>().markAsRead(
                          notification.id,
                        );
                        _navigate(notification);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectionMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 12, top: 8),
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: style.color.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(style.icon, color: style.color, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.subject,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                  ),
                                ),
                                if (notification.body.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  timeago.format(notification.createdAt),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!notification.isRead && !_selectionMode)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 6),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        ), // Consumer
      ),   // NotificationListener
    );
  }
}
