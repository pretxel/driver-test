// lib/core/router/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/available_jobs/available_jobs_screen.dart';
import '../../features/my_jobs/my_jobs_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/available-jobs',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null ||
          Supabase.instance.client.auth.currentSession != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/available-jobs';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/available-jobs',
        builder: (context, state) => const AvailableJobsScreen(),
      ),
      GoRoute(
        path: '/my-jobs',
        builder: (context, state) => const MyJobsScreen(),
      ),
    ],
  );
});
