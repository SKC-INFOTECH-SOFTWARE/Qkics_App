// lib/models/tag.dart
class Tag {
  final int id;
  final String name;
  final String slug;

  Tag({required this.id, required this.name, required this.slug});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Tag && id == other.id;

  @override
  int get hashCode => id.hashCode;
}