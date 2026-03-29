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
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
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
