import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  throw UnimplementedError();
});

class OnboardingRepository {
  final SharedPreferences sharedPreferences;
  OnboardingRepository(this.sharedPreferences);

  static const _onboardingKey = 'onboarding_complete';

  bool isOnboardingComplete() {
    return sharedPreferences.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    await sharedPreferences.setBool(_onboardingKey, true);
  }
}

final onboardingCompletedProvider = StateProvider<bool>((ref) {
  final repo = ref.watch(onboardingRepositoryProvider);
  return repo.isOnboardingComplete();
});
