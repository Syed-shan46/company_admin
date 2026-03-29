import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

// Provider
final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>(
  (ref) {
    return AuthNotifier(ref.read(authRepositoryProvider));
  },
);

class AuthRepository {
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> login(String email, String password) async {
    final response = await _api.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );

    // Backend wraps data in { success: true, data: { token: ... } }
    if (response != null && response is Map) {
      String? token;

      // Check if wrapped in 'data' field
      if (response.containsKey('data') && response['data'] is Map) {
        token = response['data']['token'];
      } else if (response.containsKey('token')) {
        // Fallback: direct token field
        token = response['token'];
      }

      if (token != null) {
        await _storage.write(key: 'auth_token', value: token);
        // print('Token saved successfully');
      } else {
        throw Exception('Login failed: No token in response');
      }
    } else {
      throw Exception('Login failed: Invalid response');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }
}

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      final isLoggedIn = await _repository.isLoggedIn();
      state = AsyncValue.data(isLoggedIn);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.login(email, password);
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(false);
  }
}
