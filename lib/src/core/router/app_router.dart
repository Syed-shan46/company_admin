import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/vendors/presentation/vendor_list_screen.dart';
import '../../features/vendors/presentation/vendor_detail_screen.dart';
import '../../features/notifications/presentation/notification_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/support/presentation/support_tickets_screen.dart';
import '../../features/support/presentation/support_chat_screen.dart';
import '../../features/wallet/screens/wallet_list_screen.dart';
import '../../features/store_types/presentation/store_types_screen.dart';
import '../../features/banners/presentation/banners_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/data/onboarding_repository.dart';

// Key for access to Context
final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isOnboardingComplete = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: _CombinedListenable([
      _AuthStateListenable(authState),
      _OnboardingListenable(isOnboardingComplete),
    ]),
    redirect: (context, state) {
      final onboardingComplete = isOnboardingComplete;
      final isOnboardingPage = state.uri.toString() == '/onboarding';

      if (!onboardingComplete) {
        return isOnboardingPage ? null : '/onboarding';
      }

      if (isOnboardingPage) {
        return '/';
      }

      final isLoggedIn = authState.valueOrNull ?? false;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return DashboardShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/store-types',
            builder: (context, state) => const StoreTypesScreen(),
          ),
          GoRoute(
            path: '/vendors',
            builder: (context, state) => const VendorListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    VendorDetailScreen(vendorId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Users')),
              body: const Center(child: Text('User Management - Coming Soon')),
            ),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Orders')),
              body: const Center(child: Text('Order Management - Coming Soon')),
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportTicketsScreen(),
            routes: [
              GoRoute(
                path: ':ticketId',
                builder: (context, state) => SupportChatScreen(
                  ticketId: state.pathParameters['ticketId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletListScreen(),
          ),
          GoRoute(
            path: '/banners',
            builder: (context, state) => const BannersScreen(),
          ),
        ],
      ),
    ],
  );
});

// Helper to convert AsyncValue to Listenable for GoRouter
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(AsyncValue<bool> state) {
    if (!state.isLoading) {
      notifyListeners();
    }
  }
}

class _OnboardingListenable extends ChangeNotifier {
  _OnboardingListenable(bool complete) {
    notifyListeners();
  }
}

class _CombinedListenable extends ChangeNotifier {
  _CombinedListenable(List<ChangeNotifier> listenables) {
    for (final listenable in listenables) {
      listenable.addListener(notifyListeners);
    }
  }
}
