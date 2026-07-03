import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_flow_config.dart';
import '../../core/providers/splash_completed_provider.dart';
import '../../features/superadmin/presentation/superadmin_routes.dart';
import '../../features/admin/presentation/admin_login_page.dart';
import '../../features/admin/models/admin_models.dart';
import '../../features/admin/presentation/admin_dashboard_page.dart';
import '../../features/admin/presentation/admin_pages.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/master_registration_screen.dart';
import '../../features/auth/presentation/master_skills_screen.dart';
import '../../features/master/presentation/master_application_submitted_screen.dart';
import '../../features/master/presentation/master_photo_screen.dart';
import '../../features/master/presentation/cabinet/master_chats_screen.dart';
import '../../features/master/presentation/cabinet/master_income_screen.dart';
import '../../features/master/presentation/cabinet/master_level_screen.dart';
import '../../features/master/presentation/cabinet/master_orders_screen.dart';
import '../../features/master/presentation/cabinet/master_portfolio_screen.dart';
import '../../features/master/presentation/cabinet/master_rating_screen.dart';
import '../../features/master/presentation/cabinet/master_schedule_screen.dart';
import '../../features/master/presentation/cabinet/master_work_zone_screen.dart';
import '../../features/auth/presentation/password_login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/role/presentation/role_selection_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'router_refresh_listenable.dart';
import 'panel_routes.dart';

String resolveInitialLocation() {
  final path = Uri.base.path;
  if (path.startsWith('/admin')) {
    if (path == '/admin' || path == '/admin/') return '/admin/dashboard';
    return path;
  }
  if (path.startsWith('/superadmin')) {
    return path == '/superadmin' ? '/superadmin/dashboard' : path;
  }

  final fragment = Uri.base.fragment;
  if (fragment.isNotEmpty) {
    final route = fragment.startsWith('/') ? fragment : '/$fragment';
    if (route.startsWith('/admin') || route.startsWith('/superadmin')) {
      return route;
    }
  }

  return '/splash';
}

bool _isPanelRoute(String location) => isPanelRoute(location);

final routerRefreshListenableProvider = Provider<RouterRefreshListenable>((ref) {
  final listenable = RouterRefreshListenable();
  ref.onDispose(listenable.dispose);
  return listenable;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerRefreshListenableProvider);

  ref.listen(authProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated ||
        previous?.isInitialized != next.isInitialized ||
        previous?.isAdmin != next.isAdmin) {
      refreshListenable.refresh();
    }
  });
  ref.listen(splashCompletedProvider, (_, __) => refreshListenable.refresh());

  final router = GoRouter(
    initialLocation: resolveInitialLocation(),
    refreshListenable: refreshListenable,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ошибка маршрута: ${state.error ?? state.uri}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final uriPath = state.uri.path;
      final panelPath =
          _isPanelRoute(location) ? location : (_isPanelRoute(uriPath) ? uriPath : null);

      // Admin panel — требует JWT с ролью Admin/SuperAdmin
      if (panelPath != null && panelPath.startsWith('/admin')) {
        if (panelPath == '/admin/login') {
          final auth = ref.read(authProvider);
          if (auth.isInitialized && auth.isAuthenticated && auth.isAdmin) {
            return resolveAdminNextRoute(state.uri.queryParameters['next']);
          }
          return null;
        }

        final auth = ref.read(authProvider);
        if (!auth.isInitialized || !auth.isAuthenticated || !auth.isAdmin) {
          return adminLoginPath(returnTo: panelPath);
        }
        if (panelPath == '/admin') return '/admin/dashboard';
        if (panelPath != location) return panelPath;
        return null;
      }

      // Superadmin — те же права Admin/SuperAdmin, данные с API после входа
      if (panelPath != null && panelPath.startsWith('/superadmin')) {
        final auth = ref.read(authProvider);
        if (!auth.isInitialized || !auth.isAuthenticated || !auth.isAdmin) {
          return adminLoginPath(returnTo: panelPath);
        }

        if (panelPath == '/superadmin') return '/superadmin/dashboard';
        if (panelPath != location) return panelPath;
        return null;
      }

      final splashDone = ref.read(splashCompletedProvider);

      if (!splashDone && location != '/splash' && !_isPanelRoute(location)) {
        return '/splash';
      }

      if (splashDone && location == '/splash') {
        return AppFlowConfig.splashGoesToHome ? '/' : '/role';
      }

      if (!AppFlowConfig.postSplashFlowEnabled) {
        if (location != '/splash') return '/splash';
        return null;
      }

      if (AppFlowConfig.splashGoesToHome && !AppFlowConfig.requireAuthForHome) {
        if (location == '/splash' || location == '/') return null;
      }

      final auth = ref.read(authProvider);

      if (location == '/role') {
        return null;
      }

      if (!auth.isInitialized) {
        if (location == '/login' ||
            location == '/login/password' ||
            location == '/login/register' ||
            location == '/master/register' ||
            location == '/master/skills' ||
            location == '/master/photo' ||
            location == '/master/submitted') {
          return null;
        }
        return '/splash';
      }

      if (auth.isAuthenticated) {
        const masterOnboarding = [
          '/master/register',
          '/master/skills',
          '/master/photo',
          '/master/submitted',
        ];
        if (masterOnboarding.contains(location) && auth.isMaster) {
          final profile = auth.masterProfile;
          if (profile == null || !profile.isApproved) {
            return null;
          }
        }

        if (location == '/login' ||
            location == '/login/password' ||
            location == '/login/register' ||
            location == '/master/register' ||
            location == '/master/skills' ||
            location == '/master/photo' ||
            location == '/master/submitted' ||
            location == '/role') {
          return auth.isMaster ? '/master/cabinet/orders' : '/';
        }
        return null;
      }

      if (location == '/login' ||
          location == '/login/password' ||
          location == '/login/register' ||
          location == '/master/register' ||
          location == '/master/skills' ||
          location == '/master/photo' ||
          location == '/master/submitted') {
        return null;
      }

      if (location == '/' && !AppFlowConfig.splashGoesToHome) {
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
        path: '/master/register',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: '/master/skills',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterSkillsScreen(),
        ),
      ),
      GoRoute(
        path: '/master/photo',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterPhotoScreen(),
        ),
      ),
      GoRoute(
        path: '/master/submitted',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterApplicationSubmittedScreen(),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/income',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterIncomeScreen(),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/orders',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterOrdersScreen(),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/active-orders',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterOrdersScreen(active: true),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/rating',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterRatingScreen(),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/schedule',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterScheduleScreen(),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/chats',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterChatsScreen(),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/zone',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterWorkZoneScreen(),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/portfolio',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterPortfolioScreen(),
        ),
      ),
      GoRoute(
        path: '/master/cabinet/level',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const MasterLevelScreen(),
        ),
      ),
      GoRoute(
        path: '/login/password',
        pageBuilder: (context, state) {
          String? phone;
          var role = state.uri.queryParameters['role'] ?? 'Client';
          if (state.extra is Map) {
            final map = state.extra! as Map;
            phone = map['phone'] as String?;
            role = map['role'] as String? ?? role;
          } else if (state.extra is String) {
            phone = state.extra as String;
          }
          return _fadePage(
            state: state,
            child: PasswordLoginScreen(initialPhone: phone, role: role),
          );
        },
      ),
      GoRoute(
        path: '/login/register',
        pageBuilder: (context, state) {
          String? phone;
          var role = state.uri.queryParameters['role'] ?? 'Client';
          if (state.extra is Map) {
            final map = state.extra! as Map;
            phone = map['phone'] as String?;
            role = map['role'] as String? ?? role;
          } else if (state.extra is String) {
            phone = state.extra as String;
          }
          return _fadePage(
            state: state,
            child: RegisterScreen(initialPhone: phone, role: role),
          );
        },
      ),
      GoRoute(
        path: '/admin/login',
        pageBuilder: (context, state) => _adminPage(
          state: state,
          child: const AdminLoginPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminDashboardPage()),
          ),
          GoRoute(
            path: '/admin/orders',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminOrdersPage()),
          ),
          GoRoute(
            path: '/admin/orders/new',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminOrdersPage(statusFilter: AdminOrderStatus.newOrder)),
          ),
          GoRoute(
            path: '/admin/orders/in-progress',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminOrdersPage(statusFilter: AdminOrderStatus.inProgress)),
          ),
          GoRoute(
            path: '/admin/orders/completed',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminOrdersPage(statusFilter: AdminOrderStatus.completed)),
          ),
          GoRoute(
            path: '/admin/orders/cancelled',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminOrdersPage(statusFilter: AdminOrderStatus.cancelled)),
          ),
          GoRoute(
            path: '/admin/masters',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminMastersPage()),
          ),
          GoRoute(
            path: '/admin/masters/pending',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminMastersPage(statusFilter: AdminMasterStatus.pending)),
          ),
          GoRoute(
            path: '/admin/masters/top',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminMastersPage(statusFilter: AdminMasterStatus.top)),
          ),
          GoRoute(
            path: '/admin/masters/blocked',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminMastersPage(statusFilter: AdminMasterStatus.blocked)),
          ),
          GoRoute(
            path: '/admin/clients',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminClientsPage()),
          ),
          GoRoute(
            path: '/admin/clients/vip',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminClientsPage(vipOnly: true)),
          ),
          GoRoute(
            path: '/admin/clients/new',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminClientsPage(newOnly: true)),
          ),
          GoRoute(
            path: '/admin/chats',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminChatsPage()),
          ),
          GoRoute(
            path: '/admin/reviews',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminReviewsPage()),
          ),
          GoRoute(
            path: '/admin/reviews/pending',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminReviewsPage(pendingOnly: true)),
          ),
          GoRoute(
            path: '/admin/reviews/flagged',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminReviewsPage(flaggedOnly: true)),
          ),
          GoRoute(
            path: '/admin/finance',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminFinancePage()),
          ),
          GoRoute(
            path: '/admin/finance/payouts',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminFinancePage(section: 'payouts')),
          ),
          GoRoute(
            path: '/admin/finance/commission',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminFinancePage(section: 'commission')),
          ),
          GoRoute(
            path: '/admin/analytics',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminAnalyticsPage()),
          ),
          GoRoute(
            path: '/admin/analytics/services',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminAnalyticsPage(section: 'services')),
          ),
          GoRoute(
            path: '/admin/analytics/districts',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminAnalyticsPage(section: 'districts')),
          ),
          GoRoute(
            path: '/admin/settings',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminSettingsPage()),
          ),
          GoRoute(
            path: '/admin/settings/categories',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminSettingsPage(section: 'categories')),
          ),
          GoRoute(
            path: '/admin/settings/promos',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminSettingsPage(section: 'promos')),
          ),
          GoRoute(
            path: '/admin/settings/notifications',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminSettingsPage(section: 'notifications')),
          ),
          GoRoute(
            path: '/admin/support',
            pageBuilder: (c, s) => _adminPage(state: s, child: const AdminSupportPage()),
          ),
        ],
      ),
      superAdminShellRoute,
    ],
  );

  return router;
});

CustomTransitionPage<void> _adminPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
  );
}

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
