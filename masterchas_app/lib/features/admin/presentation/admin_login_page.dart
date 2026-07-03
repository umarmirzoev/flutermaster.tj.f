import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/panel_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_theme.dart';
import 'widgets/admin_badges.dart';

/// Password from MasterChasDataSeeder.cs (SeedPassword).
const adminSeedPassword = 'MasterChas2025!';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _phoneController = TextEditingController(text: '900000099');
  final _passwordController = TextEditingController(text: adminSeedPassword);
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authProvider.notifier).initializeAuth();
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.isAdmin) {
        await ref.read(adminDataProvider.notifier).refresh();
        if (!mounted) return;
        final next = GoRouterState.of(context).uri.queryParameters['next'];
        context.go(resolveAdminNextRoute(next));
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canLogin =>
      !_isSubmitting &&
      _phoneController.text.trim().length >= 9 &&
      _passwordController.text.isNotEmpty;

  Future<void> _onLogin() async {
    if (!_canLogin) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).loginWithPassword(
            phone: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (!mounted) return;

      final auth = ref.read(authProvider);
      if (!auth.isAdmin) {
        await ref.read(authProvider.notifier).signOut();
        setState(() => _error = 'Нужна роль Admin или SuperAdmin');
        return;
      }

      if (!mounted) return;
      await ref.read(adminDataProvider.notifier).refresh();
      if (!mounted) return;
      final next = GoRouterState.of(context).uri.queryParameters['next'];
      context.go(resolveAdminNextRoute(next));
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: AdminTheme.pageBg,
        fontFamily: GoogleFonts.inter().fontFamily,
      ),
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AdminCard(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AdminTheme.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.shield, color: AdminTheme.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Master Chas Admin',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AdminTheme.text,
                                  ),
                                ),
                                Text(
                                  'Вход администратора',
                                  style: GoogleFonts.inter(fontSize: 13, color: AdminTheme.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Телефон',
                          hintText: '900 00 00 00',
                          prefixIcon: const Icon(LucideIcons.phone, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(LucideIcons.lock, size: 18),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? LucideIcons.eye_off : LucideIcons.eye, size: 18),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onSubmitted: (_) => _onLogin(),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Пароль из сидера: MasterChas2025!. Пользователь с ролью Admin должен быть создан на сервере.',
                        style: GoogleFonts.inter(fontSize: 11, color: AdminTheme.muted, height: 1.4),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: GoogleFonts.inter(fontSize: 13, color: AdminTheme.red),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _canLogin ? _onLogin : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AdminTheme.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Войти'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
