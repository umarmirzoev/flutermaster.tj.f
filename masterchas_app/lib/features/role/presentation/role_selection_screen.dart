import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/widgets/motion.dart';

const _clientGreen = Color(0xFF57B55E);
const _masterNavy = Color(0xFF1C2438);

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _topSlide;
  late final Animation<double> _bottomSlide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _topSlide = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)),
    );
    _bottomSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic)),
    );
    _fade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Выберите язык', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
              const SizedBox(height: 16),
              for (final lang in AppLocale.values)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: current == lang ? _clientGreen.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: current == lang ? Border.all(color: _clientGreen.withValues(alpha: 0.3)) : null,
                  ),
                  child: ListTile(
                    leading: Text(lang.code.toUpperCase(), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: _clientGreen)),
                    title: Text(lang.label, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600)),
                    trailing: current == lang ? const Icon(LucideIcons.check, color: _clientGreen) : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(lang);
                      Navigator.pop(context);
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final copy = _RoleCopy.of(locale);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _entryController,
        builder: (context, _) {
          return Stack(
            children: [
              Column(
            children: [
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, _topSlide.value),
                  child: Opacity(
                    opacity: _fade.value,
                    child: _RolePanel(
                      backgroundColor: _clientGreen,
                      iconRingColor: Colors.white.withValues(alpha: 0.22),
                      icon: const _ClientIcon(),
                      title: copy.clientTitle,
                      subtitle: copy.clientSubtitle,
                      features: const ['Поиск мастеров', 'AI подбор', 'Магазин'],
                      featureIcons: const [LucideIcons.search, LucideIcons.bot, LucideIcons.shopping_bag],
                      topTrailing: _LanguageChip(locale: locale, onTap: () => _showLanguageSheet(context, ref)),
                      onTap: () => context.go('/login'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, _bottomSlide.value),
                  child: Opacity(
                    opacity: _fade.value,
                    child: _RolePanel(
                      backgroundColor: _masterNavy,
                      iconRingColor: Colors.white.withValues(alpha: 0.14),
                      icon: const _MasterIcon(),
                      title: copy.masterTitle,
                      subtitle: copy.masterSubtitle,
                      features: const ['Заказы', 'Доход', 'Рейтинг'],
                      featureIcons: const [LucideIcons.clipboard_list, LucideIcons.trending_up, LucideIcons.star],
                      onTap: () => context.go('/login/master-code'),
                      delay: const Duration(milliseconds: 200),
                    ),
                  ),
                ),
              ),
            ],
              ),
              const Align(alignment: Alignment.center, child: _CenterBadge()),
            ],
          );
        },
      ),
    );
  }
}

class _RoleCopy {
  const _RoleCopy({required this.clientTitle, required this.clientSubtitle, required this.masterTitle, required this.masterSubtitle});
  final String clientTitle, clientSubtitle, masterTitle, masterSubtitle;

  static _RoleCopy of(AppLocale locale) => switch (locale) {
    AppLocale.ru => const _RoleCopy(clientTitle: 'Я клиент', clientSubtitle: 'Если вы заказчик или клиент, войдите здесь', masterTitle: 'Я мастер', masterSubtitle: 'Если вы мастер или исполнитель, войдите здесь'),
    AppLocale.en => const _RoleCopy(clientTitle: 'I am a client', clientSubtitle: 'If you are a customer or client, sign in here', masterTitle: 'I am a master', masterSubtitle: 'If you are a master or service provider, sign in here'),
    AppLocale.tg => const _RoleCopy(clientTitle: 'Ман мизоҷ ҳастам', clientSubtitle: 'Агар шумо мизоҷ ё фармоишдиҳанда бошед, ин ҷо ворид шавед', masterTitle: 'Ман усто ҳастам', masterSubtitle: 'Агар шумо усто ё иҷрокунанда бошед, ин ҷо ворид шавед'),
    AppLocale.zh => const _RoleCopy(clientTitle: '我是客户', clientSubtitle: '如果您是客户或订购者，请在此登录', masterTitle: '我是师傅', masterSubtitle: '如果您是师傅或服务提供者，请在此登录'),
  };
}

class _RolePanel extends StatefulWidget {
  const _RolePanel({
    required this.backgroundColor,
    required this.iconRingColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.features,
    required this.featureIcons,
    this.topTrailing,
    this.accent = Colors.white,
    this.delay = Duration.zero,
  });

  final Color backgroundColor, iconRingColor, accent;
  final Widget icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final Widget? topTrailing;
  final List<String> features;
  final List<IconData> featureIcons;
  final Duration delay;

  @override
  State<_RolePanel> createState() => _RolePanelState();
}

class _RolePanelState extends State<_RolePanel> with SingleTickerProviderStateMixin {
  bool _hover = false;
  bool _pressed = false;
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final bg = w.backgroundColor;
    final useTopSafeArea = w.topTrailing != null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: w.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(bg, Colors.white, _hover ? 0.12 : 0.06)!,
                bg,
                Color.lerp(bg, Colors.black, 0.18)!,
              ],
            ),
          ),
          child: ClipRect(
            child: SafeArea(
              top: useTopSafeArea,
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 360;
                  final ringSize = compact ? 80.0 : 100.0;
                  final titleSize = compact ? 26.0 : 30.0;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Медленно вращающийся ключ на фоне
                      Positioned(
                        right: -40,
                        top: -30,
                        child: RotationTransition(
                          turns: _spin,
                          child: Icon(LucideIcons.settings, size: 200, color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      ),
                      Positioned(
                        left: -50,
                        bottom: -40,
                        child: FloatY(
                          amplitude: 8,
                          period: const Duration(milliseconds: 5200),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
                          ),
                        ),
                      ),
                      // Плавающие точки
                      for (final (i, pos) in const [(0.12, 0.25), (0.85, 0.6), (0.2, 0.75), (0.7, 0.18)].indexed)
                        Positioned(
                          left: constraints.maxWidth * pos.$1,
                          top: constraints.maxHeight * pos.$2,
                          child: FloatY(
                            amplitude: 6,
                            phase: i * 0.27,
                            period: Duration(milliseconds: 2600 + i * 500),
                            child: Container(
                              width: 6.0 + i * 2,
                              height: 6.0 + i * 2,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.18)),
                            ),
                          ),
                        ),
                      if (w.topTrailing != null)
                        Positioned(top: 8, right: 16, child: w.topTrailing!),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        child: AnimatedScale(
                          scale: _pressed ? 0.97 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: constraints.maxWidth - 40,
                              child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Reveal(
                                delay: w.delay,
                                offsetY: 16,
                                child: FloatY(
                                  amplitude: 4,
                                  child: PulseRing(
                                    color: Colors.white,
                                    size: ringSize,
                                    child: AnimatedScale(
                                      scale: _hover ? 1.08 : 1,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutBack,
                                      child: _IconRing(size: ringSize, color: w.iconRingColor, child: w.icon),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 12 : 18),
                              Reveal(
                                delay: w.delay + const Duration(milliseconds: 90),
                                child: Text(
                                  w.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(fontSize: titleSize, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1),
                                ),
                              ),
                              SizedBox(height: compact ? 5 : 8),
                              Reveal(
                                delay: w.delay + const Duration(milliseconds: 150),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    w.subtitle,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.88), height: 1.35),
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 10 : 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: List.generate(w.features.length, (i) {
                                  return Reveal(
                                    delay: w.delay + Duration(milliseconds: 220 + 70 * i),
                                    offsetY: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.13),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(w.featureIcons[i], size: 12, color: Colors.white),
                                          const SizedBox(width: 5),
                                          Text(
                                            w.features[i],
                                            style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: compact ? 14 : 22),
                              Reveal(
                                delay: w.delay + const Duration(milliseconds: 420),
                                offsetY: 14,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
                                  child: ShineSweep(
                                    radius: 30,
                                    delay: w.delay + const Duration(milliseconds: 900),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: _hover ? 0.28 : 0.16),
                                            blurRadius: _hover ? 22 : 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Войти',
                                            style: GoogleFonts.manrope(fontSize: 15.5, fontWeight: FontWeight.w800, color: bg),
                                          ),
                                          const SizedBox(width: 8),
                                          AnimatedSlide(
                                            offset: Offset(_hover ? 0.3 : 0, 0),
                                            duration: const Duration(milliseconds: 250),
                                            child: Icon(LucideIcons.arrow_right, color: bg, size: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Логотип на стыке двух половин экрана.
class _CenterBadge extends StatelessWidget {
  const _CenterBadge();

  @override
  Widget build(BuildContext context) {
    return Reveal(
      delay: const Duration(milliseconds: 500),
      offsetY: 0,
      child: FloatY(
        amplitude: 3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: _clientGreen, shape: BoxShape.circle),
                child: const Icon(LucideIcons.wrench, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 7),
              Text(
                'Master.tj',
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w900, color: _masterNavy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.locale, required this.onTap});
  final AppLocale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 22,
      lift: 2,
      scale: 1.05,
      child: Material(
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
              Icon(LucideIcons.globe, size: 16, color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(width: 6),
              Text(locale.code.toUpperCase(), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevron_down, size: 16, color: Colors.white.withValues(alpha: 0.9)),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _IconRing extends StatelessWidget {
  const _IconRing({required this.size, required this.color, required this.child});
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.white.withValues(alpha: 0.08), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _ClientIcon extends StatelessWidget {
  const _ClientIcon();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48, height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(LucideIcons.user, color: Colors.white, size: 42),
          Positioned(right: 0, bottom: 0, child: Icon(LucideIcons.search, color: Colors.white.withValues(alpha: 0.95), size: 18)),
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
      width: 48, height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(angle: -0.55, child: const Icon(LucideIcons.hammer, color: Colors.white, size: 40)),
          Transform.rotate(angle: 0.55, child: const Icon(LucideIcons.wrench, color: Colors.white, size: 36)),
        ],
      ),
    );
  }
}
