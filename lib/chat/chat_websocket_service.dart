import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatWebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(
    int roomId,
    String token, {
    required Function(Map<String, dynamic>) onMessageReceived,
    required Function(Map<String, dynamic>) onMessageRead,
    required Function(Map<String, dynamic>) onTyping,
    required Function(Map<String, dynamic>) onStatusUpdate,
    required Function(dynamic) onError,
    required VoidCallback onDone,
  }) {
    final wsUrl = "ws://192.168.0.114:1000/ws/chat/$roomId/?token=$token";

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          final type = data['type'];

          if (type == 'chat_message') {
            onMessageReceived(data);
          } else if (type == 'typing') {
            onTyping(data);
          } else if (type == 'user_status') {
            onStatusUpdate(data);
          } else if (type == 'message_read') {
            onMessageRead(data);
          }
        },
        onError: (err) {
          _isConnected = false;
          onError(err);
        },
        onDone: () {
          _isConnected = false;
          onDone();
        },
      );
    } catch (e) {
      _isConnected = false;
      onError(e);
    }
  }

  void sendMessage(String text, {String? filePath}) {
    if (_channel != null && _isConnected) {
      final data = {
        'type': 'chat_message',
        'text': text,
        if (filePath != null) 'file': filePath,
      };
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void setTyping(bool isTyping) {
    if (_channel != null && _isConnected) {
      final data = {'type': 'typing', 'is_typing': isTyping};
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void markAsRead(int messageId) {
    if (_channel != null && _isConnected) {
      final data = {'type': 'message_read', 'message_id': messageId};
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}

typedef VoidCallback = void Function();
