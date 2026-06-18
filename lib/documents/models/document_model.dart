class Document {
  final String? uuid;
  final String title;
  final String description;
  final String accessType;
  final bool isActive;
  final DateTime? createdAt;
  final String? file;

  Document({
    this.uuid,
    required this.title,
    required this.description,
    required this.accessType,
    this.isActive = true,
    this.createdAt,
    this.file,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      uuid: json['uuid'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      accessType: json['access_type'] ?? 'FREE',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      file: json['file'],
    );
  }

  Document copyWith({bool? isActive}) {
    return Document(
      uuid: uuid,
      title: title,
      description: description,
      accessType: accessType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      file: file,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (uuid != null) 'uuid': uuid,
      'title': title,
      'description': description,
      'access_type': accessType,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (file != null) 'file': file,
    };
  }
}
