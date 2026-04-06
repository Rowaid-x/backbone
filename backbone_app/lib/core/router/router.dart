import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/schedule/schedule_screen.dart';
import '../../features/checklist/checklist_screen.dart';
import '../../features/checklist/checklist_version_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/schedule',
    redirect: (context, state) {
      if (!authState.isAuthenticated) {
        return state.matchedLocation == '/login' ? null : '/login';
      }
      if (state.matchedLocation == '/login') return '/schedule';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen()),
          GoRoute(path: '/checklist', builder: (_, __) => const ChecklistScreen()),
          GoRoute(
            path: '/checklist/version/:id',
            builder: (_, state) => ChecklistVersionScreen(
              versionId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
        ],
      ),
    ],
  );
});
