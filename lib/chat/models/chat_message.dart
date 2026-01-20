import 'package:q_kics/models/user.dart';

class ChatMessage {
  final int id;
  final User sender;
  final String text;
  final String? fileUrl;
  final DateTime timestamp;
  final bool isRead;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.fileUrl,
    required this.timestamp,
    required this.isRead,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sender: User.fromJson(json['sender']),
      text: json['text'] ?? '',
      fileUrl: json['file_url'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      isMine: json['is_mine'] ?? false,
    );
  }

  factory ChatMessage.fromWsJson(
    Map<String, dynamic> json,
    String currentUsername,
  ) {
    final senderUsername = json['sender'];
    final isMine = senderUsername == currentUsername;

    return ChatMessage(
      id: json['id'],
      sender: User(
        id: 0,
        username: senderUsername,
        email: '',
        phone: '',
        firstName: '',
        lastName: '',
        userType: 'normal',
        status: 'active',
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      text: json['text'] ?? '',
      fileUrl: json['file'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: false,
      isMine: isMine,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'text': text,
      'file_url': fileUrl,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'is_mine': isMine,
    };
  }
}
