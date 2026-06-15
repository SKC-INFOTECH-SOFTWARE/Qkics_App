class CallUser {
  final int id;
  final String uuid;
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  const CallUser({
    required this.id,
    required this.uuid,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : username;
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return (f + l).isNotEmpty ? (f + l) : username[0].toUpperCase();
  }

  factory CallUser.fromJson(Map<String, dynamic> j) => CallUser(
        id: j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
        uuid: j['uuid'] ?? '',
        username: j['username'] ?? '',
        firstName: j['first_name'] ?? '',
        lastName: j['last_name'] ?? '',
        profilePicture: j['profile_picture'],
      );
}

class CallRoom {
  final String id;
  final String status; // WAITING | ACTIVE | ENDED
  final CallUser user;
  final CallUser advisor;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final bool canJoin;
  final String? livekitToken;
  final String? livekitUrl;

  const CallRoom({
    required this.id,
    required this.status,
    required this.user,
    required this.advisor,
    this.scheduledStart,
    this.scheduledEnd,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.canJoin,
    this.livekitToken,
    this.livekitUrl,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isWaiting => status == 'WAITING';
  bool get isEnded => status == 'ENDED';

  factory CallRoom.fromJson(Map<String, dynamic> j) => CallRoom(
        id: j['id'].toString(),
        status: j['status'] ?? 'WAITING',
        user: CallUser.fromJson(j['user']),
        advisor: CallUser.fromJson(j['advisor']),
        scheduledStart: j['scheduled_start'] != null
            ? DateTime.parse(j['scheduled_start'])
            : null,
        scheduledEnd: j['scheduled_end'] != null
            ? DateTime.parse(j['scheduled_end'])
            : null,
        startedAt:
            j['started_at'] != null ? DateTime.parse(j['started_at']) : null,
        endedAt:
            j['ended_at'] != null ? DateTime.parse(j['ended_at']) : null,
        durationSeconds: j['duration_seconds'],
        canJoin: j['can_join'] ?? false,
        livekitToken: j['livekit_token'],
        livekitUrl: j['livekit_url'],
      );
}

class CallChatMessage {
  final int? id;
  final int senderId;
  final String senderUsername;
  final String senderFullName;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool    isFile;
  final String? fileUrl;
  final String? fileName;

  const CallChatMessage({
    this.id,
    required this.senderId,
    required this.senderUsername,
    required this.senderFullName,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isFile = false,
    this.fileUrl,
    this.fileName,
  });

  factory CallChatMessage.fromWsData({
    required Map<String, dynamic> data,
    required int currentUserId,
  }) {
    final sid = data['sender_id'];
    final senderId = sid is int ? sid : int.tryParse(sid?.toString() ?? '') ?? 0;

    final fileUrl = data['file_url'] as String?;
    final isFile = (data['is_file'] as bool?) ?? (fileUrl != null && fileUrl.isNotEmpty);

    final rawTs = data['timestamp'] ?? data['created_at'];
    final timestamp = rawTs != null
        ? DateTime.tryParse(rawTs.toString()) ?? DateTime.now()
        : DateTime.now();

    final isMe = data['is_mine'] as bool? ?? (senderId == currentUserId);

    return CallChatMessage(
      id: data['message_id'],
      senderId: senderId,
      senderUsername: data['sender_username'] ?? '',
      senderFullName: data['sender_username'] ?? '',
      text: data['text'] ?? '',
      timestamp: timestamp,
      isMe: isMe,
      isFile: isFile,
      fileUrl: fileUrl,
      fileName: data['file_name'],
    );
  }

  factory CallChatMessage.fromJson(
    Map<String, dynamic> j,
    int currentUserId,
  ) {
    // sender can be an int id, a string id, or a nested user object
    final senderField = j['sender'] ?? j['sender_id'];
    int senderId = 0;
    String senderUsername = j['sender_username'] ?? '';
    if (senderField is int) {
      senderId = senderField;
    } else if (senderField is String) {
      senderId = int.tryParse(senderField) ?? 0;
    } else if (senderField is Map) {
      final id = senderField['id'];
      senderId = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
      if (senderUsername.isEmpty) {
        senderUsername = senderField['username']?.toString() ?? '';
      }
    }

    // Server may omit is_file but always includes file_url when it's a file.
    final fileUrl = j['file_url'] as String?;
    final isFile = (j['is_file'] as bool?) ?? (fileUrl != null && fileUrl.isNotEmpty);

    // Server uses created_at; fallback to timestamp for WS-style payloads.
    final rawTs = j['created_at'] ?? j['timestamp'];
    final timestamp = rawTs != null
        ? DateTime.tryParse(rawTs.toString()) ?? DateTime.now()
        : DateTime.now();

    // Prefer server-supplied is_mine when available.
    final isMe = j['is_mine'] as bool? ?? (senderId == currentUserId);

    return CallChatMessage(
      id: j['id'],
      senderId: senderId,
      senderUsername: senderUsername,
      senderFullName: senderUsername,
      text: j['text'] ?? '',
      timestamp: timestamp,
      isMe: isMe,
      isFile: isFile,
      fileUrl: fileUrl,
      fileName: j['file_name'],
    );
  }
}
