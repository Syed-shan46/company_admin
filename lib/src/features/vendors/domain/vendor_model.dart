import 'package:company_admin/src/core/constants/api_constants.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_model.g.dart';

@JsonSerializable()
class Vendor {
  @JsonKey(name: '_id')
  final String id;

  final String ownerName;
  final String email;
  final String businessName;
  final String businessType; // grocery, restaurant

  // Status: "pending", "approved", "rejected", "banned"
  final String status;

  final String? profileImage;
  final String? coverImage;
  final bool? isOpenManualOverride;

  // Basic Vendor Fields
  @JsonKey(defaultValue: false)
  final bool isGlobalVisible;
  @JsonKey(defaultValue: 'restaurant')
  final String vendorType;

  String? get fullProfileImageUrl =>
      profileImage != null && profileImage!.startsWith('/uploads')
      ? '${ApiConstants.imageBaseUrl}$profileImage'
      : profileImage;

  String? get fullCoverImageUrl =>
      coverImage != null && coverImage!.startsWith('/uploads')
      ? '${ApiConstants.imageBaseUrl}$coverImage'
      : coverImage;

  Vendor({
    required this.id,
    required this.ownerName,
    required this.email,
    required this.businessName,
    required this.businessType,
    required this.status,
    this.profileImage,
    this.coverImage,
    this.isOpenManualOverride,
    this.isGlobalVisible = false,
    this.vendorType = 'restaurant',
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => _$VendorFromJson(json);
  Map<String, dynamic> toJson() => _$VendorToJson(this);
}
