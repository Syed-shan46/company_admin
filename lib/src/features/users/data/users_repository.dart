import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/user_model.dart';

final usersRepositoryProvider = Provider((ref) => UsersRepository());

// Auto-refreshable provider for VendorUsers
final vendorUsersListProvider = FutureProvider<List<VendorUser>>((ref) async {
  final repo = ref.watch(usersRepositoryProvider);
  return repo.fetchVendorUsers();
});

// Auto-refreshable provider for Customers
final customersListProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.watch(usersRepositoryProvider);
  return repo.fetchCustomers();
});

class UsersRepository {
  final ApiClient _api = ApiClient();

  Future<List<VendorUser>> fetchVendorUsers() async {
    final response = await _api.get('${ApiConstants.adminVendorUsers}?limit=100');

    if (response != null && response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        return data.map((e) => VendorUser.fromJson(e)).toList();
      }
    } else if (response != null && response is List) {
      return response.map((e) => VendorUser.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Customer>> fetchCustomers() async {
    final response = await _api.get('${ApiConstants.adminCustomers}?limit=100');

    if (response != null && response is Map && response.containsKey('data')) {
      final data = response['data'];
      if (data is List) {
        return data.map((e) => Customer.fromJson(e)).toList();
      }
    } else if (response != null && response is List) {
      return response.map((e) => Customer.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> deleteVendorUser(String userId) async {
    try {
      final response = await _api.delete(ApiConstants.deleteVendorUser(userId));
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      final response = await _api.delete(ApiConstants.deleteCustomer(customerId));
      return response != null;
    } catch (e) {
      return false;
    }
  }
}
