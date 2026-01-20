import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/chat/models/chat_room.dart';
import 'package:q_kics/providers/chat_provider.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/chat/screens/chat_messages_page.dart';
import 'package:intl/intl.dart';

class ChatRoomsPage extends StatefulWidget {
  const ChatRoomsPage({super.key});

  @override
  State<ChatRoomsPage> createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchChatRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProv, child) {
          if (chatProv.isLoadingRooms) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProv.roomsError != null) {
            return Center(child: Text("Error: ${chatProv.roomsError}"));
            print("Error loading chat rooms: ${chatProv.roomsError}");
          }

          if (chatProv.rooms.isEmpty) {
            return const Center(child: Text("No conversations found."));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chatProv.rooms.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 72,
              endIndent: 16,
              color: Colors.black12,
            ),
            itemBuilder: (context, index) {
              final room = chatProv.rooms[index];
              return _RoomTile(room: room);
            },
          );
        },
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoom room; 
  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<ApiProvider>().currentUser;
    final otherUser = room.user.id == currentUser?.id ? room.expert : room.user;

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatMessagesPage(room: room)),
        );
      },
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: otherUser.profileImage != null
            ? NetworkImage(otherUser.profileImage!)
            : null,
        child: otherUser.profileImage == null ? Text(otherUser.initials) : null,
      ),
      title: Text(
        otherUser.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        room.lastMessage ?? "Start a conversation",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (room.lastMessageAt != null)
            Text(
              DateFormat('h:mm a').format(room.lastMessageAt!),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          const SizedBox(height: 4),
          // Unread indicator could go here if available in API
        ],
      ),
    );
  }
}
