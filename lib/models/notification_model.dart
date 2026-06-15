// lib/models/notification_model.dart
class NotificationModel {
  final String id;
  final String? event;
  final String subject;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.event,
    required this.subject,
    required this.body,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

 factory NotificationModel.fromJson(Map<String, dynamic> json) {
  return NotificationModel(
    id: (json['_id'] ?? json['id'] ?? '').toString(),

    event: json['event'],

    subject: json['renderedSubject'] ??
             json['subject'] ??
             '',

    body: json['renderedBody'] ??
          json['body'] ??
          '',

    data: json['data'] is Map<String, dynamic>
        ? json['data']
        : {},

    readAt: json['readAt'] != null
        ? DateTime.parse(json['readAt'])
        : null,

    createdAt: DateTime.parse(
      json['createdAt'] ??
      DateTime.now().toIso8601String(),
    ),
  );
}

  NotificationModel copyWith({
    String? id,
    String? event,
    String? subject,
    String? body,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      event: event ?? this.event,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
