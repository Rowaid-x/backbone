import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/shows/show_cards_screen.dart';
import '../../features/shows/show_table_screen.dart';
import '../../features/actions/my_actions_screen.dart';
import '../../features/users/users_screen.dart';
import '../../features/users/user_profile_screen.dart';
import '../../shared/widgets/coming_soon.dart';
import '../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) async {
      final isLoggedIn = ref.read(isLoggedInProvider);
      final goingToLogin = state.matchedLocation == '/login';
      if (!isLoggedIn && !goingToLogin) return '/login';
      if (isLoggedIn && goingToLogin) return '/dashboard';
      return null;
    },
    refreshListenable: RouterNotifier(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Dashboard
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),

          // My Profile
          GoRoute(path: '/profile', builder: (_, __) => const UserProfileScreen(isSelf: true)),

          // Shows
          GoRoute(
            path: '/shows',
            redirect: (_, __) => '/shows/cards',
          ),
          GoRoute(path: '/shows/glance', builder: (_, __) => const ComingSoonScreen(featureName: 'At a Glance')),
          GoRoute(path: '/shows/cards', builder: (_, __) => const ShowCardsScreen()),
          GoRoute(path: '/shows/table', builder: (_, __) => const ShowTableScreen()),

          // Planning (Phase 2)
          GoRoute(path: '/planning/overview', builder: (_, __) => const ComingSoonScreen(featureName: 'Drone Planning')),
          GoRoute(path: '/planning/reservations', builder: (_, __) => const ComingSoonScreen(featureName: 'Drone Reservations')),
          GoRoute(path: '/planning/calendar', builder: (_, __) => const ComingSoonScreen(featureName: 'Drone Calendar')),

          // Actions
          GoRoute(path: '/actions/all', builder: (_, __) => const ComingSoonScreen(featureName: 'All Actions')),
          GoRoute(path: '/actions/my', builder: (_, __) => const MyActionsScreen()),

          // Scheduling (Phase 2)
          GoRoute(path: '/shifts/crew-calendar', builder: (_, __) => const ComingSoonScreen(featureName: 'Crew Calendar')),
          GoRoute(path: '/shifts/shifts', builder: (_, __) => const ComingSoonScreen(featureName: 'Shifts')),
          GoRoute(path: '/shifts/work-approvals', builder: (_, __) => const ComingSoonScreen(featureName: 'Work Approvals')),

          // Travel (Phase 2)
          GoRoute(path: '/travel/all', builder: (_, __) => const ComingSoonScreen(featureName: 'All Travel')),
          GoRoute(path: '/travel/my', builder: (_, __) => const ComingSoonScreen(featureName: 'My Travel')),

          // People
          GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
          GoRoute(
            path: '/users/:id',
            builder: (_, state) => UserProfileScreen(userId: state.pathParameters['id']),
          ),

          // Account (Phase 2)
          GoRoute(path: '/account/appearance', builder: (_, __) => const ComingSoonScreen(featureName: 'Appearance')),
          GoRoute(path: '/account/settings', builder: (_, __) => const ComingSoonScreen(featureName: 'App Settings')),
          GoRoute(path: '/account/notifications', builder: (_, __) => const ComingSoonScreen(featureName: 'Notifications')),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod auth state to GoRouter's refreshListenable
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(isLoggedInProvider, (_, __) => notifyListeners());
  }
}
