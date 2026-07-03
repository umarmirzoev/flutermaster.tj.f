import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/admin_data.dart';
import '../models/admin_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_theme.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _searchCtrl = TextEditingController();
  bool _showSearchResults = false;

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
    final ui = ref.watch(adminUiProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final sidebarW = ui.sidebarCollapsed ? AdminTheme.sidebarCollapsed : AdminTheme.sidebarWidth;

    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: AdminTheme.pageBg,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      child: Scaffold(
        backgroundColor: AdminTheme.pageBg,
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sidebarW,
              color: AdminTheme.sidebarBg,
              child: _Sidebar(
                collapsed: ui.sidebarCollapsed,
                location: location,
                expandedMenus: ui.expandedMenus,
                onToggleMenu: (id) => ref.read(adminUiProvider.notifier).toggleMenu(id),
                onCollapse: () => ref.read(adminUiProvider.notifier).toggleSidebar(),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    searchCtrl: _searchCtrl,
                    showResults: _showSearchResults,
                    onSearchChanged: (v) {
                      ref.read(adminUiProvider.notifier).setSearch(v);
                      setState(() => _showSearchResults = v.isNotEmpty);
                    },
                    onSearchTap: () => setState(() => _showSearchResults = _searchCtrl.text.isNotEmpty),
                    onResultTap: (route) {
                      context.go(route);
                      setState(() => _showSearchResults = false);
                      _searchCtrl.clear();
                      ref.read(adminUiProvider.notifier).setSearch('');
                    },
                    onDismissSearch: () => setState(() => _showSearchResults = false),
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.location,
    required this.expandedMenus,
    required this.onToggleMenu,
    required this.onCollapse,
  });

  final bool collapsed;
  final String location;
  final Set<String> expandedMenus;
  final ValueChanged<String> onToggleMenu;
  final VoidCallback onCollapse;

  bool _isActive(String route) => location == route || location.startsWith('$route/');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(collapsed ? 12 : 16, 20, collapsed ? 12 : 16, 16),
          child: Row(
            children: [
              if (!collapsed) ...[
                Text('Master Chas', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
              ],
              Icon(LucideIcons.panel_left, size: 18, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final item in adminMenuItems) ...[
                _NavItem(
                  item: item,
                  collapsed: collapsed,
                  active: _isActive(item.route),
                  expanded: expandedMenus.contains(item.id),
                  onTap: () {
                    if (item.children.isNotEmpty) {
                      onToggleMenu(item.id);
                    }
                    context.go(item.route);
                  },
                  onChildTap: (route) => context.go(route),
                  expandedMenus: expandedMenus,
                ),
              ],
            ],
          ),
        ),
        InkWell(
          onTap: onCollapse,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(collapsed ? LucideIcons.panel_left_open : LucideIcons.panel_left_close, size: 16, color: Colors.white54),
                if (!collapsed) ...[
                  const SizedBox(width: 8),
                  Text('Свернуть', style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.collapsed,
    required this.active,
    required this.expanded,
    required this.onTap,
    required this.onChildTap,
    required this.expandedMenus,
  });

  final AdminMenuItem item;
  final bool collapsed;
  final bool active;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<String> onChildTap;
  final Set<String> expandedMenus;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return Column(
      children: [
        Material(
          color: active ? AdminTheme.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: AdminTheme.sidebarHover,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12, vertical: 10),
              child: Row(
                mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(item.icon, size: 18, color: Colors.white),
                  if (!collapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AdminTheme.red, borderRadius: BorderRadius.circular(10)),
                        child: Text('${item.badge}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    if (item.children.isNotEmpty)
                      Icon(expanded ? LucideIcons.chevron_down : LucideIcons.chevron_right, size: 14, color: Colors.white54),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!collapsed && expanded && item.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 2, bottom: 4),
            child: Column(
              children: [
                for (final child in item.children)
                  InkWell(
                    onTap: () => onChildTap(child.route),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: location == child.route ? AdminTheme.sidebarHover : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(child.label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.searchCtrl,
    required this.showResults,
    required this.onSearchChanged,
    required this.onSearchTap,
    required this.onResultTap,
    required this.onDismissSearch,
  });

  final TextEditingController searchCtrl;
  final bool showResults;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onResultTap;
  final VoidCallback onDismissSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(adminUiProvider).searchQuery;
    final async = ref.watch(adminDataProvider);
    final results = async.maybeWhen(
      data: (data) => globalAdminSearch(data, query),
      orElse: () => const <Map<String, String>>[],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      decoration: const BoxDecoration(
        color: AdminTheme.cardBg,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Row(
        children: [
          Text('Admin Dashboard', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AdminTheme.text)),
          const SizedBox(width: 32),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminTheme.pageBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.search, size: 16, color: AdminTheme.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: onSearchChanged,
                          onTap: onSearchTap,
                          style: GoogleFonts.inter(fontSize: 13, color: AdminTheme.text),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Поиск по заказам, пользователям, мастерам...',
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: AdminTheme.muted),
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
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          color: AdminTheme.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminTheme.border),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final r = results[i] as Map<String, String>;
                            return ListTile(
                              dense: true,
                              title: Text(r['label']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text(r['type']!, style: GoogleFonts.inter(fontSize: 11, color: AdminTheme.muted)),
                              onTap: () => onResultTap(r['route']!),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              IconButton(icon: const Icon(LucideIcons.bell, size: 20, color: AdminTheme.text), onPressed: () {}),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AdminTheme.red, shape: BoxShape.circle),
                  child: Text('17', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
          IconButton(icon: const Icon(LucideIcons.message_circle, size: 20, color: AdminTheme.text), onPressed: () => context.go('/admin/chats')),
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw, size: 20, color: AdminTheme.text),
            onPressed: () => ref.read(adminDataProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.log_out, size: 20, color: AdminTheme.text),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/admin/login');
            },
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AdminTheme.green.withValues(alpha: 0.15),
                child: Text('A', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AdminTheme.green)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.text)),
                  Text('Администратор', style: GoogleFonts.inter(fontSize: 11, color: AdminTheme.muted)),
                ],
              ),
              const Icon(LucideIcons.chevron_down, size: 14, color: AdminTheme.muted),
            ],
          ),
        ],
      ),
    );
  }
}
