// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vendor _$VendorFromJson(Map<String, dynamic> json) => Vendor(
  id: json['_id'] as String,
  ownerName: json['ownerName'] as String,
  email: json['email'] as String,
  businessName: json['businessName'] as String,
  businessType: json['businessType'] as String,
  status: json['status'] as String,
  profileImage: json['profileImage'] as String?,
  coverImage: json['coverImage'] as String?,
  isOpenManualOverride: json['isOpenManualOverride'] as bool?,
  isGlobalVisible: json['isGlobalVisible'] as bool? ?? false,
  vendorType: json['vendorType'] as String? ?? 'restaurant',
);

Map<String, dynamic> _$VendorToJson(Vendor instance) => <String, dynamic>{
  '_id': instance.id,
  'ownerName': instance.ownerName,
  'email': instance.email,
  'businessName': instance.businessName,
  'businessType': instance.businessType,
  'status': instance.status,
  'profileImage': instance.profileImage,
  'coverImage': instance.coverImage,
  'isOpenManualOverride': instance.isOpenManualOverride,
  'isGlobalVisible': instance.isGlobalVisible,
  'vendorType': instance.vendorType,
};
