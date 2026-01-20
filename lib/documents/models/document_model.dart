class Document {
  final String uuid;
  final String title;
  final String description;
  final String accessType;
  final bool isActive;
  final DateTime createdAt;
  final String? fileUrl;

  Document({
    required this.uuid,
    required this.title,
    required this.description,
    required this.accessType,
    this.isActive = true,
    required this.createdAt,
    this.fileUrl,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      uuid: json['uuid'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      accessType: json['access_type'] ?? 'FREE',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      fileUrl: json['file_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'access_type': accessType,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'file_url': fileUrl,
    };
  }
}
