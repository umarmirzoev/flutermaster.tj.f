import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/client_onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/password_login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/role/presentation/role_selection_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;

      if (location == '/splash' ||
          location == '/role' ||
          location == '/client/onboarding') {
        return null;
      }

      if (!auth.isInitialized) {
        return '/splash';
      }

      if (auth.isAuthenticated) {
        if (location == '/login' ||
            location == '/login/password' ||
            location == '/role' ||
            location == '/client/onboarding') {
          return '/';
        }
        return null;
      }

      if (location == '/') {
        return '/role';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/role',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const RoleSelectionScreen(),
        ),
      ),
      GoRoute(
        path: '/client/onboarding',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const ClientOnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/login/password',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const PasswordLoginScreen(),
        ),
      ),
    ],
  );

  ref.listen(authProvider, (_, __) => router.refresh());

  return router;
});

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 550),
    reverseTransitionDuration: const Duration(milliseconds: 550),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  );
}
