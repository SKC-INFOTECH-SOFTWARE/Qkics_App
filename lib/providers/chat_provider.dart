import 'package:flutter/material.dart';
import 'package:q_kics/chat/chat_api_service.dart';
import 'package:q_kics/chat/chat_websocket_service.dart';
import 'package:q_kics/chat/models/chat_message.dart';
import 'package:q_kics/chat/models/chat_room.dart';

class ChatProvider with ChangeNotifier {
  final ChatApiService _apiService = ChatApiService();
  final ChatWebSocketService _wsService = ChatWebSocketService();

  List<ChatRoom> _rooms = [];
  bool _isLoadingRooms = false;
  String? _roomsError;

  List<ChatMessage> _messages = [];
  bool _isLoadingMessages = false;
  String? _messagesError;

  bool _isOtherTyping = false;
  Set<int> _onlineUsers = {};

  List<ChatRoom> get rooms => _rooms;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get roomsError => _roomsError;

  List<ChatMessage> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get messagesError => _messagesError;
  bool get isOtherTyping => _isOtherTyping;
  Set<int> get onlineUsers => _onlineUsers;

  Future<void> fetchChatRooms() async {
    _isLoadingRooms = true;
    _roomsError = null;
    notifyListeners();

    try {
      _rooms = await _apiService.getChatRooms();
    } catch (e) {
      _roomsError = e.toString();
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }
void markAllIncomingAsRead(int currentUserId) {
  bool updated = false;

  for (int i = 0; i < _messages.length; i++) {
    final msg = _messages[i];

    if (!msg.isMine && !msg.isRead) {
      // 🔥 Optimistic UI update
      _messages[i] = ChatMessage(
        id: msg.id,
        sender: msg.sender,
        text: msg.text,
        fileUrl: msg.fileUrl,
        timestamp: msg.timestamp,
        isRead: true,
        isMine: msg.isMine,
      );

      // 🔥 Notify server
      _wsService.markAsRead(msg.id);

      updated = true;
    }
  }

  if (updated) {
    _messages = List.from(_messages); // force rebuild
    notifyListeners();
  }
}

  Future<void> fetchChatMessages(int roomId) async {
    _isLoadingMessages = true;
    _messagesError = null;
    // Clearing messages before fetch to feel fresh
    _messages = [];
    notifyListeners();

    try {
      _messages = await _apiService.getChatMessages(roomId);
    } catch (e) {
      _messagesError = e.toString();
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(int roomId, String text, {String? filePath}) async {
    try {
      // Per instructions, sending via WebSocket
      _wsService.sendMessage(text, filePath: filePath);
      return true;
    } catch (e) {
      print("Error in provider sendMessage: $e");
      return false;
    }
  }

  Future<void> connectToRoom(
    int roomId,
    String token,
    String currentUsername,
    int currentUserId,
  ) async {
    _wsService.disconnect();
    _wsService.connect(
      roomId,
      token,
      onMessageReceived: (data) {
  final message = ChatMessage.fromWsJson(data, currentUsername);

  if (!_messages.any((m) => m.id == message.id)) {
    _messages.add(message);
    notifyListeners();

    // 🔥 Auto mark as read if chat is open
    if (!message.isMine) {
      _wsService.markAsRead(message.id);

      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: message.id,
          sender: message.sender,
          text: message.text,
          fileUrl: message.fileUrl,
          timestamp: message.timestamp,
          isRead: true,
          isMine: false,
        );
        _messages = List.from(_messages);
        notifyListeners();
      }
    }
  }
},

      onMessageRead: (data) {
        print("DEBUG: Message Read Event Received: $data");
        // Try multiple keys for message ID
        final rawId = data['message_id'] ?? data['id'];
        if (rawId == null) return;

        final messageId = rawId.toString();

        final index = _messages.indexWhere((m) => m.id.toString() == messageId);
        if (index != -1) {
          final oldMessage = _messages[index];
          if (!oldMessage.isRead) {
            _messages[index] = ChatMessage(
              id: oldMessage.id,
              sender: oldMessage.sender,
              text: oldMessage.text,
              fileUrl: oldMessage.fileUrl,
              timestamp: oldMessage.timestamp,
              isRead: true,
              isMine: oldMessage.isMine,
            );
            // Force list reference change to ensure Consumers rebuild properly
            _messages = List.from(_messages);
            notifyListeners();
          }
        }
      },
      onTyping: (data) {
        // If the typing event is from me, ignore it
        if (data['user_id'] == currentUserId) return;

        _isOtherTyping = data['is_typing'] ?? false;
        notifyListeners();
      },
      onStatusUpdate: (data) {
        final userId = data['user_id'];
        final online = data['online'] ?? false;
        if (online) {
          _onlineUsers.add(userId);
        } else {
          _onlineUsers.remove(userId);
        }
        notifyListeners();
      },
      onError: (err) => print("WS Error: $err"),
      onDone: () => print("WS Connection Closed"),
    );
  }

  void disconnectFromRoom({bool notify = true}) {
    _wsService.disconnect();
    _isOtherTyping = false;
    if (notify) {
      notifyListeners();
    }
  }

  void sendTyping(bool isTyping) {
    _wsService.setTyping(isTyping);
  }

  void markAsRead(int messageId) {
    _wsService.markAsRead(messageId);
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}
