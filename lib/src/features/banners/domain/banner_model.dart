import '../../../core/constants/api_constants.dart';

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
    String url = map['imageUrl'] ?? '';
    if (url.startsWith('/uploads')) {
      url = '${ApiConstants.imageBaseUrl}$url';
    }

    return PromoBanner(
      id: id,
      imageUrl: url,

      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'imageUrl': imageUrl, 'createdAt': createdAt.toIso8601String()};
  }
}
