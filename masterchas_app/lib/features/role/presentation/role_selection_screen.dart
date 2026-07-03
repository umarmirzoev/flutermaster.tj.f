import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/providers/locale_provider.dart';

/// Same green as splash screen.
const _clientGreen = Color(0xFF57B55E);

/// Dark navy from role-selection reference.
const _masterNavy = Color(0xFF1C2438);

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final copy = _RoleCopy.of(locale);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _RolePanel(
              backgroundColor: _clientGreen,
              iconRingColor: Colors.white.withValues(alpha: 0.22),
              icon: const _ClientIcon(),
              title: copy.clientTitle,
              subtitle: copy.clientSubtitle,
              topTrailing: _LanguageChip(
                locale: locale,
                onTap: () => _showLanguageSheet(context, ref),
              ),
              onTap: () => context.go('/login'),
            ),
          ),
          Expanded(
            child: _RolePanel(
              backgroundColor: _masterNavy,
              iconRingColor: Colors.white.withValues(alpha: 0.14),
              icon: const _MasterIcon(),
              title: copy.masterTitle,
              subtitle: copy.masterSubtitle,
              onTap: () => context.go('/login?role=Master'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              for (final lang in AppLocale.values)
                ListTile(
                  leading: Text(
                    lang.code.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF57B55E),
                    ),
                  ),
                  title: Text(
                    lang.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: current == lang
                      ? const Icon(LucideIcons.check, color: Color(0xFF57B55E))
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(lang);
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _RoleCopy {
  const _RoleCopy({
    required this.clientTitle,
    required this.clientSubtitle,
    required this.masterTitle,
    required this.masterSubtitle,
  });

  final String clientTitle;
  final String clientSubtitle;
  final String masterTitle;
  final String masterSubtitle;

  static _RoleCopy of(AppLocale locale) {
    return switch (locale) {
      AppLocale.ru => const _RoleCopy(
          clientTitle: 'Я клиент',
          clientSubtitle: 'Если вы заказчик или клиент, войдите здесь',
          masterTitle: 'Я мастер',
          masterSubtitle: 'Если вы мастер или исполнитель, войдите здесь',
        ),
      AppLocale.en => const _RoleCopy(
          clientTitle: 'I am a client',
          clientSubtitle: 'If you are a customer or client, sign in here',
          masterTitle: 'I am a master',
          masterSubtitle: 'If you are a master or service provider, sign in here',
        ),
      AppLocale.tg => const _RoleCopy(
          clientTitle: 'Ман мизоҷ ҳастам',
          clientSubtitle: 'Агар шумо мизоҷ ё фармоишдиҳанда бошед, ин ҷо ворид шавед',
          masterTitle: 'Ман усто ҳастам',
          masterSubtitle: 'Агар шумо усто ё иҷрокунанда бошед, ин ҷо ворид шавед',
        ),
      AppLocale.zh => const _RoleCopy(
          clientTitle: '我是客户',
          clientSubtitle: '如果您是客户或订购者，请在此登录',
          masterTitle: '我是师傅',
          masterSubtitle: '如果您是师傅或服务提供者，请在此登录',
        ),
    };
  }
}

class _RolePanel extends StatelessWidget {
  const _RolePanel({
    required this.backgroundColor,
    required this.iconRingColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.topTrailing,
  });

  final Color backgroundColor;
  final Color iconRingColor;
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? topTrailing;

  @override
  Widget build(BuildContext context) {
    final useTopSafeArea = topTrailing != null;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          top: useTopSafeArea,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 320;
              final ringSize = compact ? 96.0 : 118.0;
              final titleSize = compact ? 24.0 : 28.0;
              final subtitleSize = compact ? 13.0 : 14.0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (topTrailing != null)
                      Align(
                        alignment: Alignment.topRight,
                        child: topTrailing!,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 52),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        _IconRing(
                          size: ringSize,
                          color: iconRingColor,
                          child: icon,
                        ),
                        SizedBox(height: compact ? 14 : 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: compact ? 6 : 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: subtitleSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.35,
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: _ArrowButton(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.locale,
    required this.onTap,
  });

  final AppLocale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.globe,
                size: 16,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 6),
              Text(
                locale.code.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevron_down,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconRing extends StatelessWidget {
  const _IconRing({
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: const Icon(
        LucideIcons.arrow_right,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _ClientIcon extends StatelessWidget {
  const _ClientIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            LucideIcons.user,
            color: Colors.white,
            size: 48,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              LucideIcons.search,
              color: Colors.white.withValues(alpha: 0.95),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterIcon extends StatelessWidget {
  const _MasterIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.55,
            child: const Icon(
              LucideIcons.hammer,
              color: Colors.white,
              size: 46,
            ),
          ),
          Transform.rotate(
            angle: 0.55,
            child: const Icon(
              LucideIcons.wrench,
              color: Colors.white,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}
