import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  NotificationRepository();

  Future<void> sendBroadcast({
    required String title,
    required String body,
  }) async {
    // ApiClient throws exception on non-200 status
    await _apiClient.post(
      ApiConstants.sendBroadcast,
      body: {'title': title, 'body': body},
    );
  }

  Future<void> sendVendorPromotion({
    required String vendorId,
    required String content,
    String target = 'all',
  }) async {
    // ApiClient throws exception on non-200 status
    await _apiClient.post(
      ApiConstants.sendVendorPromotion,
      body: {'vendorId': vendorId, 'content': content, 'target': target},
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});
