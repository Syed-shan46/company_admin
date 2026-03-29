import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:company_admin/src/core/network/api_client.dart';
import '../../store_types/domain/store_type_model.dart';

// Provider for fetching store types
final storeTypesProvider = FutureProvider.autoDispose<List<StoreType>>((
  ref,
) async {
  final repository = ref.watch(storeTypeRepositoryProvider);
  return repository.getStoreTypes();
});

// Repository provider
final storeTypeRepositoryProvider = Provider<StoreTypeRepository>((ref) {
  return StoreTypeRepository(ref.watch(apiClientProvider));
});

class StoreTypeRepository {
  final ApiClient _apiClient;

  StoreTypeRepository(this._apiClient);

  Future<List<StoreType>> getStoreTypes() async {
    try {
      // API Client handles headers/tokens
      final response = await _apiClient.get('store-types/all');

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => StoreType.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      try {
        final response = await _apiClient.get('store-types');
        if (response['success'] == true) {
          final List<dynamic> data = response['data'];
          return data.map((json) => StoreType.fromJson(json)).toList();
        }
        return [];
      } catch (e2) {
        throw Exception('Failed to load store types: $e');
      }
    }
  }

  Future<void> createStoreType(String name, String icon) async {
    await _apiClient.post('store-types', body: {'name': name, 'icon': icon});
  }

  Future<void> updateStoreType(
    String id,
    String name,
    String icon,
    bool isActive,
  ) async {
    await _apiClient.patch(
      'store-types/$id',
      body: {'name': name, 'icon': icon, 'isActive': isActive},
    );
  }

  Future<void> deleteStoreType(String id) async {
    await _apiClient.delete('store-types/$id');
  }
}
