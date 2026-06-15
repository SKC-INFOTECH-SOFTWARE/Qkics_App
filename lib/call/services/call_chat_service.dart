import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef VoidCallback = void Function();

class CallChatService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  static const String _wsBaseUrl = 'wss://qkicsbackend.matchb.online';
  // static const String _wsBaseUrl = 'ws://192.168.0.109:7880';

  void connect({
    required String roomId,
    required String token,
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(Map<String, dynamic>) onTyping,
    required VoidCallback onCallEnded,
    required void Function(dynamic) onError,
    required VoidCallback onDone,
  }) {
    // Defensive: disconnect any existing channel before opening a new one.
    _closeChannel();

    final wsUrl = '$_wsBaseUrl/ws/calls/$roomId/?token=$token';

    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (raw) {
          // Guard every message individually — a bad frame must not kill the
          // stream or propagate into the notifier.
          try {
            if (raw is! String) return;
            final data = jsonDecode(raw) as Map<String, dynamic>;
            final type = data['type'];

            if (type == 'call_message' ||
                type == 'file_message' ||
                type == 'new_message' ||
                type == 'message') {
              try { onMessage(data); } catch (e) {
                debugPrint('[CallChat] onMessage handler error: $e');
              }
            } else if (type == 'typing') {
              try { onTyping(data); } catch (e) {
                debugPrint('[CallChat] onTyping handler error: $e');
              }
            } else if (type == 'call_ended') {
              try { onCallEnded(); } catch (e) {
                debugPrint('[CallChat] onCallEnded handler error: $e');
              }
            } else {
              debugPrint('[CallChat] unhandled type "$type": $data');
              // If it looks like a chat/file payload, treat it as a message.
              if (data.containsKey('file_url') || data.containsKey('text')) {
                try { onMessage(data); } catch (e) {
                  debugPrint('[CallChat] fallback onMessage error: $e');
                }
              }
            }
          } catch (e) {
            // Swallow parse/decode errors — the stream must stay alive.
            debugPrint('[CallChat] message parse error: $e');
          }
        },
        onError: (e) {
          _isConnected = false;
          try { onError(e); } catch (_) {}
        },
        onDone: () {
          _isConnected = false;
          try { onDone(); } catch (_) {}
        },
        cancelOnError: false, // keep stream alive on individual errors
      );
    } catch (e) {
      _isConnected = false;
      debugPrint('[CallChat] connect error: $e');
      try { onError(e); } catch (_) {}
    }
  }

  void sendMessage(String text) {
    _safeSend({'type': 'call_message', 'text': text});
  }

  /// Broadcasts a file message to all room participants via WebSocket.
  /// Called by the uploader after a successful HTTP upload so the receiver
  /// sees the file instantly without waiting for a server-side WS broadcast.
  void sendFileMessage({
    required int? messageId,
    required String fileUrl,
    required String fileName,
    required int senderId,
    required String senderUsername,
    String text = '',
  }) {
    _safeSend({
      'type': 'call_message',
      if (messageId != null) 'message_id': messageId,
      'sender_id': senderId,
      'sender_username': senderUsername,
      'file_url': fileUrl,
      'file_name': fileName,
      'text': text,
      'is_file': true,
    });
  }

  void sendTyping(bool isTyping) {
    _safeSend({'type': 'typing', 'is_typing': isTyping});
  }

  void sendCallEnded() {
    _safeSend({'type': 'call_ended'});
  }

  void disconnect() => _closeChannel();

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _safeSend(Map<String, dynamic> payload) {
    if (_channel == null || !_isConnected) return;
    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint('[CallChat] send error: $e');
      _isConnected = false;
    }
  }

  void _closeChannel() {
    _isConnected = false;
    try { _subscription?.cancel(); } catch (_) {}
    _subscription = null;
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;
  }
}
