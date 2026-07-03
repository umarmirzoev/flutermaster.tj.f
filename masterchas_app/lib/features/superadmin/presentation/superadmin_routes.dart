import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'superadmin_dashboard_page.dart';
import 'superadmin_pages.dart';
import 'superadmin_shell.dart';

CustomTransitionPage<void> superAdminPage({
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

ShellRoute get superAdminShellRoute => ShellRoute(
      builder: (context, state, child) => SuperAdminShell(child: child),
      routes: [
        GoRoute(path: '/superadmin/dashboard', pageBuilder: (c, s) => superAdminPage(state: s, child: const SuperAdminDashboardPage())),
        GoRoute(path: '/superadmin/fund', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaFundPage())),
        GoRoute(path: '/superadmin/orders', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaOrdersPage())),
        GoRoute(path: '/superadmin/masters', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaMastersPage())),
        GoRoute(path: '/superadmin/clients', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaClientsPage())),
        GoRoute(path: '/superadmin/shop', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaShopPage())),
        GoRoute(path: '/superadmin/products', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaProductsPage())),
        GoRoute(path: '/superadmin/categories', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaCategoriesPage())),
        GoRoute(path: '/superadmin/brands', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaBrandsPage())),
        GoRoute(path: '/superadmin/coupons', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaCouponsPage())),
        GoRoute(path: '/superadmin/chats', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaChatsPage())),
        GoRoute(path: '/superadmin/reviews', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaReviewsPage())),
        GoRoute(path: '/superadmin/finance', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaFinancePage())),
        GoRoute(path: '/superadmin/analytics', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaAnalyticsPage())),
        GoRoute(path: '/superadmin/marketing', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaMarketingPage())),
        GoRoute(path: '/superadmin/pages', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaPagesPage())),
        GoRoute(path: '/superadmin/notifications', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaNotificationsPage())),
        GoRoute(path: '/superadmin/support', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaSupportPage())),
        GoRoute(path: '/superadmin/settings', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaSettingsPage())),
        GoRoute(path: '/superadmin/system', pageBuilder: (c, s) => superAdminPage(state: s, child: const SaSystemPage())),
      ],
    );
