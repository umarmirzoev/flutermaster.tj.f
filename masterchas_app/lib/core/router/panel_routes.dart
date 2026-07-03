bool isPanelRoute(String location) =>
    location.startsWith('/admin') || location.startsWith('/superadmin');

String adminLoginPath({String? returnTo}) {
  if (returnTo == null ||
      returnTo.isEmpty ||
      returnTo == '/admin/login' ||
      !isPanelRoute(returnTo)) {
    return '/admin/login';
  }
  return '/admin/login?next=${Uri.encodeComponent(returnTo)}';
}

String resolveAdminNextRoute(String? next) {
  if (next != null && next.isNotEmpty && isPanelRoute(next) && next != '/admin/login') {
    return next;
  }
  return '/admin/dashboard';
}
