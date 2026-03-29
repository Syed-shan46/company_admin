import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/vendor_model.dart';

final vendorRepositoryProvider = Provider((ref) => VendorRepository());

final vendorsProvider = FutureProvider.family<List<Vendor>, String>((
  ref,
  statusFilter,
) async {
  final repo = ref.watch(vendorRepositoryProvider);
  return repo.fetchVendors(status: statusFilter);
});

final vendorDetailProvider = FutureProvider.family<Vendor?, String>((
  ref,
  vendorId,
) async {
  final repo = ref.watch(vendorRepositoryProvider);
  return repo.fetchVendorById(vendorId);
});

class VendorRepository {
  final ApiClient _api = ApiClient();

  Future<List<Vendor>> fetchVendors({String status = 'all'}) async {
    final url = status == 'all'
        ? ApiConstants.adminVendors
        : '${ApiConstants.adminVendors}?status=$status';

    final response = await _api.get(url);

    // Backend wraps in { data: [...] }
    if (response != null && response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        return data.map((e) => Vendor.fromJson(e)).toList();
      }
    } else if (response != null && response is List) {
      return response.map((e) => Vendor.fromJson(e)).toList();
    }
    return [];
  }

  Future<Vendor?> fetchVendorById(String id) async {
    final response = await _api.get('${ApiConstants.adminVendors}/$id');
    if (response != null && response is Map) {
      final data = response.containsKey('data') ? response['data'] : response;
      if (data is Map<String, dynamic>) {
        return Vendor.fromJson(data);
      }
    }
    return null;
  }

  Future<void> approveVendor(String id) async {
    await _api.patch(ApiConstants.approveVendor(id));
  }

  Future<void> rejectVendor(String id, String reason) async {
    await _api.patch(ApiConstants.rejectVendor(id), body: {'reason': reason});
  }

  Future<void> toggleBasicVendorVisibility(String id, bool isVisible) async {
    await _api.patch(
      ApiConstants.basicVendorVisibility(id),
      body: {'isGlobalVisible': isVisible},
    );
  }

  Future<void> addBasicVendorProduct(
    String vendorId,
    String name,
    String description,
    double price,
    String imagePath,
  ) async {
    await _api.postMultipart(
      ApiConstants.basicVendorProducts(vendorId),
      fields: {
        'name': name,
        'description': description,
        'price': price.toString(),
      },
      files: {'image': imagePath},
    );
  }
}
