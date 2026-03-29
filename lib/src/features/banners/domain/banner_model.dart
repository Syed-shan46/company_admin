class PromoBanner {
  final String id;
  final String imageUrl;
  final DateTime createdAt;

  PromoBanner({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PromoBanner.fromMap(Map<String, dynamic> map, String id) {
    return PromoBanner(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'imageUrl': imageUrl, 'createdAt': createdAt.toIso8601String()};
  }
}
