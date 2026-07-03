import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/models/auth_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/admin_provider.dart';
import '../../../core/providers/platform_store_provider.dart';
import '../data/superadmin_data.dart';
import '../models/superadmin_models.dart';
import '../providers/superadmin_provider.dart';
import '../theme/superadmin_theme.dart';

class SuperAdminShell extends ConsumerStatefulWidget {
  const SuperAdminShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends ConsumerState<SuperAdminShell> {
  final _searchCtrl = TextEditingController();
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authProvider.notifier).initializeAuth();
      if (ref.read(authProvider).isAdmin) {
        await ref.read(adminDataProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(superAdminUiProvider);
    final auth = ref.watch(authProvider);
    final apiState = ref.watch(adminDataProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final sidebarW = ui.sidebarCollapsed ? SuperAdminTheme.sidebarCollapsed : SuperAdminTheme.sidebarWidth;

    return Theme(
      data: ThemeData(scaffoldBackgroundColor: SuperAdminTheme.pageBg, fontFamily: GoogleFonts.inter().fontFamily),
      child: Scaffold(
        backgroundColor: SuperAdminTheme.pageBg,
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sidebarW,
              color: SuperAdminTheme.sidebarBg,
              child: _Sidebar(
                collapsed: ui.sidebarCollapsed,
                location: location,
                auth: auth,
                onCollapse: () => ref.read(superAdminUiProvider.notifier).toggleSidebar(),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    auth: auth,
                    searchCtrl: _searchCtrl,
                    showResults: _showResults,
                    onSearchChanged: (v) {
                      ref.read(superAdminUiProvider.notifier).setSearch(v);
                      setState(() => _showResults = v.isNotEmpty);
                    },
                    onResultTap: (route) {
                      context.go(route);
                      setState(() => _showResults = false);
                      _searchCtrl.clear();
                      ref.read(superAdminUiProvider.notifier).setSearch('');
                    },
                  ),
                  if (auth.isAdmin)
                    apiState.when(
                      loading: () => _ApiStatusBar(
                        message: 'Загрузка заказов и клиентов с сервера…',
                        loading: true,
                      ),
                      error: (e, _) => _ApiStatusBar(
                        message: 'Не удалось загрузить данные: $e',
                        onRetry: () => ref.read(adminDataProvider.notifier).refresh(),
                      ),
                      data: (data) {
                        if (data.orders.isEmpty && data.clients.isEmpty) {
                          return _ApiStatusBar(
                            message: 'На сервере пока нет заказов и клиентов',
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiStatusBar extends StatelessWidget {
  const _ApiStatusBar({
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: loading ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            if (loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(LucideIcons.info, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.location,
    required this.auth,
    required this.onCollapse,
  });

  final bool collapsed;
  final String location;
  final AuthState auth;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(collapsed ? 14 : 18, 20, collapsed ? 14 : 18, 12),
          child: Row(
            children: [
              if (!collapsed) Expanded(child: Text('Master Chas', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
              Icon(LucideIcons.panel_left, size: 18, color: Colors.white54),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final item in superAdminMenu)
                _navItem(context, item, collapsed, location == item.route || location.startsWith('${item.route}/')),
              if (!collapsed) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Быстрые действия', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                _quickAction(context, LucideIcons.plus, 'Создать заказ', '/superadmin/orders'),
                _quickAction(context, LucideIcons.package_plus, 'Добавить товар', '/superadmin/products'),
                _quickAction(context, LucideIcons.user_plus, 'Добавить мастера', '/superadmin/masters'),
                _quickAction(context, LucideIcons.send, 'Отправить рассылку', '/superadmin/marketing'),
              ],
            ],
          ),
        ),
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: SuperAdminTheme.green.withValues(alpha: 0.2),
                  child: Text(
                    _userInitial(auth),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: SuperAdminTheme.green),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userTitle(auth),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        auth.isAdmin ? 'Супер администратор' : 'Требуется вход',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        InkWell(
          onTap: onCollapse,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(collapsed ? LucideIcons.panel_left_open : LucideIcons.panel_left_close, size: 16, color: Colors.white54),
                if (!collapsed) ...[const SizedBox(width: 8), Text('Свернуть', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54))],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _navItem(BuildContext context, SaMenuItem item, bool collapsed, bool active) {
    return Material(
      color: active ? SuperAdminTheme.sidebarActive : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(8),
        hoverColor: SuperAdminTheme.sidebarHover,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 9),
          child: Row(
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(item.icon, size: 17, color: Colors.white),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(child: Text(item.label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white))),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: item.badgeColor ?? SuperAdminTheme.green, borderRadius: BorderRadius.circular(8)),
                    child: Text(item.badge!, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70))),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.auth,
    required this.searchCtrl,
    required this.showResults,
    required this.onSearchChanged,
    required this.onResultTap,
  });

  final AuthState auth;

  final TextEditingController searchCtrl;
  final bool showResults;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onResultTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(superAdminUiProvider).searchQuery;
    final data = ref.watch(superAdminDataProvider);
    final results = platformSearch(data, query);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: const BoxDecoration(color: SuperAdminTheme.cardBg, border: Border(bottom: BorderSide(color: SuperAdminTheme.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Панель управления', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: SuperAdminTheme.text)),
                  Text('Добро пожаловать обратно, ${_userTitle(auth)}!', style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.muted)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: SuperAdminTheme.border), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [const Text('🇷🇺', style: TextStyle(fontSize: 14)), const SizedBox(width: 6), Text('Русский', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))]),
              ),
              const SizedBox(width: 10),
              _badgeIcon(LucideIcons.bell, '24'),
              const SizedBox(width: 6),
              _badgeIcon(LucideIcons.message_circle, '12', onTap: () => context.go('/superadmin/chats')),
              const SizedBox(width: 10),
              Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: SuperAdminTheme.green.withValues(alpha: 0.15), child: Text(_userInitial(auth), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: SuperAdminTheme.green, fontSize: 12))),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userTitle(auth), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(auth.isAdmin ? 'Супер администратор' : 'Гость', style: GoogleFonts.inter(fontSize: 10, color: SuperAdminTheme.muted)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(color: SuperAdminTheme.pageBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: SuperAdminTheme.border)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(LucideIcons.search, size: 16, color: SuperAdminTheme.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Поиск по заказам, пользователям, товарам...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: SuperAdminTheme.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showResults && results.isNotEmpty)
                Positioned(
                  top: 44,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(color: SuperAdminTheme.cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: SuperAdminTheme.border)),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final r = results[i];
                          return ListTile(
                            dense: true,
                            title: Text(r['label']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(r['type']!, style: GoogleFonts.inter(fontSize: 11, color: SuperAdminTheme.muted)),
                            onTap: () => onResultTap(r['route']!),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeIcon(IconData icon, String count, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 20, color: SuperAdminTheme.text)),
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: const BoxDecoration(color: SuperAdminTheme.red, borderRadius: BorderRadius.all(Radius.circular(8))),
              child: Text(count, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

String _userTitle(AuthState auth) {
  if (auth.displayName?.trim().isNotEmpty == true && auth.displayName != 'Пользователь') {
    return auth.displayName!.trim();
  }
  if (auth.phone?.isNotEmpty == true) {
    return auth.phone!;
  }
  return auth.isAdmin ? 'Admin' : 'Гость';
}

String _userInitial(AuthState auth) {
  final title = _userTitle(auth);
  return title.isNotEmpty ? title[0].toUpperCase() : '?';
}
