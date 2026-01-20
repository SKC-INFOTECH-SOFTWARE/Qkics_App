import 'package:q_kics/models/user.dart';

class ChatRoom {
  final int id;
  final User user;
  final User expert;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;

  ChatRoom({
    required this.id,
    required this.user,
    required this.expert,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    String? lastMessageStr;
    final lm = json['last_message'];
    if (lm is String) {
      lastMessageStr = lm;
    } else if (lm is Map) {
      lastMessageStr = lm['text'];
    }

    return ChatRoom(
      id: json['id'],
      user: User.fromJson(json['user']),
      expert: User.fromJson(json['expert']),
      createdAt: DateTime.parse(json['created_at']),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      lastMessage: lastMessageStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'expert': expert.toJson(),
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message': lastMessage,
    };
  }
}
