import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchStats();
});

class DashboardRepository {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchStats() async {
    final response = await _api.get(ApiConstants.dashboardStats);
    if (response != null && response is Map<String, dynamic>) {
      // Backend wraps data in "data" field if using standard response util?
      // Check admin.controller.js implementation: successResponse(res, 200, 'Stats retrieved', { ... })
      // Usually successResponse puts data in `data` key or root?
      // Let's assume root or `data`. My ApiClient returns jsonDecode(response.body).

      if (response.containsKey('data')) {
        return response['data'] as Map<String, dynamic>;
      }
      return response;
    }
    return {};
  }
}
