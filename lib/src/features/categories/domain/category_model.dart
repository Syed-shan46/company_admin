import 'package:company_admin/src/core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

@immutable
class Category {
  final String id;
  final String name;
  final String? image;
  final String? imagePublicId;
  final bool isCommon;
  final String businessType;
  final String? vendorId;

  const Category({
    required this.id,
    required this.name,
    this.image,
    this.imagePublicId,
    required this.isCommon,
    required this.businessType,
    this.vendorId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image'];
    if (imageUrl != null && imageUrl.startsWith('/uploads')) {
      imageUrl = '${ApiConstants.imageBaseUrl}$imageUrl';
    }

    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: imageUrl,
      imagePublicId: json['imagePublicId'],
      isCommon: json['isCommon'] ?? false,
      businessType: json['businessType'] ?? 'grocery',
      vendorId: json['vendorId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isCommon': isCommon,
      'businessType': businessType,
      if (vendorId != null) 'vendorId': vendorId,
    };
  }
}
