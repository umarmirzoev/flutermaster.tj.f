import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/home_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../data/ai_master_matcher.dart';
import '../data/masters_data.dart';
import 'master_detail_page.dart';
import 'masters_page.dart';
import '../../../core/widgets/motion.dart';

enum _AiPickerStep { form, thinking, results }

void showAiMasterPickerSheet(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => const Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: _AiPickerDialog(),
    ),
  );
}

class _AiPickerDialog extends ConsumerWidget {
  const _AiPickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = HomeStrings.of(locale);
    final p = HomePalette.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390, maxHeight: 640),
        child: Material(
          color: p.cardBg,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          child: _AiPickerBody(s: s, p: p, locale: locale),
        ),
      ),
    );
  }
}

class _AiPickerBody extends StatefulWidget {
  const _AiPickerBody({required this.s, required this.p, required this.locale});

  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;

  @override
  State<_AiPickerBody> createState() => _AiPickerBodyState();
}

class _AiPickerBodyState extends State<_AiPickerBody> with SingleTickerProviderStateMixin {
  final _problemController = TextEditingController();
  final _budgetController = TextEditingController();
  late final AnimationController _pulse;

  _AiPickerStep _step = _AiPickerStep.form;
  String? _district;
  String _urgency = 'normal';
  AiMatchResult? _result;

  HomeStrings get s => widget.s;
  HomePalette get p => widget.p;
  AppLocale get locale => widget.locale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _problemController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _step = _AiPickerStep.form;
      _result = null;
    });
  }

  Future<void> _submit() async {
    final text = _problemController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.aiEnterProblem, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: brandGreen,
        ),
      );
      return;
    }

    setState(() => _step = _AiPickerStep.thinking);

    final budget = int.tryParse(_budgetController.text.trim());
    final district = _district == s.aiDistrictAny ? null : _district;
    final urgent = _urgency == 'urgent';

    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final result = analyzeProblem(
      text,
      district: district,
      budget: budget,
      urgent: urgent,
    );

    setState(() {
      _result = result;
      _step = _AiPickerStep.results;
    });
  }

  void _openAllMasters() {
    final cat = _result?.category.ru;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      SmoothRoute<void>(
        builder: (_) => MastersPage(initialFilter: cat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(s: s, p: p, onClose: () => Navigator.of(context).pop()),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: switch (_step) {
              _AiPickerStep.form => _FormView(
                  key: const ValueKey('form'),
                  s: s,
                  p: p,
                  problemController: _problemController,
                  budgetController: _budgetController,
                  district: _district,
                  urgency: _urgency,
                  onDistrict: (v) => setState(() => _district = v),
                  onUrgency: (v) => setState(() => _urgency = v),
                  onSubmit: _submit,
                ),
              _AiPickerStep.thinking => _ThinkingView(
                  key: const ValueKey('thinking'),
                  s: s,
                  p: p,
                  pulse: _pulse,
                ),
              _AiPickerStep.results => _ResultsView(
                  key: const ValueKey('results'),
                  s: s,
                  p: p,
                  locale: locale,
                  result: _result!,
                  onChange: _resetForm,
                  onAllMasters: _openAllMasters,
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.s, required this.p, required this.onClose});

  final HomeStrings s;
  final HomePalette p;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6DD674), Color(0xFF4BAF50), Color(0xFF2E7D32)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -30,
            child: FloatY(
              amplitude: 6,
              period: const Duration(milliseconds: 4200),
              child: Icon(LucideIcons.sparkles, size: 120, color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FloatY(
                  amplitude: 3,
                  child: PulseRing(
                    color: Colors.white,
                    size: 48,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(LucideIcons.brain_circuit, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.aiModalTitle,
                              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('AI', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.aiModalSub,
                        style: GoogleFonts.manrope(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9), height: 1.35),
                      ),
                    ],
                  ),
                ),
                HoverLift(
                  radius: 18,
                  lift: 2,
                  scale: 1.1,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onClose,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(LucideIcons.x, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatefulWidget {
  const _FormView({
    super.key,
    required this.s,
    required this.p,
    required this.problemController,
    required this.budgetController,
    required this.district,
    required this.urgency,
    required this.onDistrict,
    required this.onUrgency,
    required this.onSubmit,
  });

  final HomeStrings s;
  final HomePalette p;
  final TextEditingController problemController;
  final TextEditingController budgetController;
  final String? district;
  final String urgency;
  final ValueChanged<String?> onDistrict;
  final ValueChanged<String> onUrgency;
  final VoidCallback onSubmit;

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  bool _focused = false;

  // Быстрые примеры — нажал, и текст подставился.
  static const _examples = [
    ('⚡', 'Не работает розетка'),
    ('💧', 'Течёт кран на кухне'),
    ('❄️', 'Кондиционер не охлаждает'),
    ('💡', 'Повесить люстру'),
    ('🚪', 'Сломался замок двери'),
  ];

  Widget _label(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: brandGreen),
            const SizedBox(width: 6),
            Text(text, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800, color: widget.p.text)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final p = widget.p;
    final hasText = widget.problemController.text.trim().isNotEmpty;
    final urgent = widget.urgency == 'urgent';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: _label(s.aiDescribeLabel, LucideIcons.message_circle)),
          Reveal(
            delay: const Duration(milliseconds: 60),
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: brandGreen.withValues(alpha: _focused ? 0.22 : 0.05),
                      blurRadius: _focused ? 22 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: widget.problemController,
                  maxLines: 4,
                  minLines: 3,
                  cursorColor: brandGreen,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.manrope(fontSize: 13.5, color: p.text, height: 1.4),
                  decoration: InputDecoration(
                    hintText: s.aiDescribeHint,
                    hintStyle: GoogleFonts.manrope(fontSize: 12.5, color: p.muted, height: 1.35),
                    filled: true,
                    fillColor: p.cardBg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: p.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: brandGreen.withValues(alpha: 0.3), width: 1.3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: brandGreen, width: 1.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Примеры проблем
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _examples.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (emoji, text) = _examples[i];
                return Reveal(
                  delay: Duration(milliseconds: 120 + 60 * i),
                  offsetY: 0,
                  offsetX: 20,
                  child: HoverLift(
                    radius: 17,
                    lift: 2,
                    scale: 1.05,
                    child: GestureDetector(
                      onTap: () {
                        widget.problemController.text = text;
                        widget.problemController.selection =
                            TextSelection.collapsed(offset: text.length);
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: brandGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: brandGreen.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '$emoji $text',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: p.text),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.aiDescribeHelper,
            style: GoogleFonts.manrope(fontSize: 10.5, color: p.muted, height: 1.35),
          ),
          const SizedBox(height: 18),
          // Район
          Reveal(
            delay: const Duration(milliseconds: 160),
            child: _DropdownField(
              label: s.aiDistrictLabel,
              value: widget.district,
              hint: s.aiDistrictHint,
              items: [s.aiDistrictAny, ...masterDistricts],
              p: p,
              onChanged: widget.onDistrict,
            ),
          ),
          const SizedBox(height: 14),
          // Срочность — две большие кнопки
          Reveal(
            delay: const Duration(milliseconds: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(s.aiUrgencyLabel, LucideIcons.clock),
                Row(
                  children: [
                    Expanded(
                      child: _ChoiceChip(
                        label: s.aiUrgencyNormal,
                        icon: LucideIcons.calendar,
                        selected: !urgent,
                        color: brandGreen,
                        p: p,
                        onTap: () => widget.onUrgency('normal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChoiceChip(
                        label: s.aiUrgencyUrgent,
                        icon: LucideIcons.zap,
                        selected: urgent,
                        color: const Color(0xFFEF4444),
                        p: p,
                        onTap: () => widget.onUrgency('urgent'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Бюджет
          Reveal(
            delay: const Duration(milliseconds: 280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(s.aiBudgetLabel, LucideIcons.wallet),
                TextField(
                  controller: widget.budgetController,
                  keyboardType: TextInputType.number,
                  cursorColor: brandGreen,
                  style: GoogleFonts.manrope(fontSize: 13.5, color: p.text, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: s.aiBudgetHint,
                    hintStyle: GoogleFonts.manrope(fontSize: 12.5, color: p.muted),
                    suffixText: 'с.',
                    suffixStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: p.muted),
                    isDense: true,
                    filled: true,
                    fillColor: p.cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: p.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: p.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: brandGreen, width: 1.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Reveal(
            delay: const Duration(milliseconds: 340),
            child: _GlowButton(
              label: s.aiPickBtn,
              enabled: hasText,
              onTap: widget.onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.p,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final HomePalette p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 14,
      lift: 2,
      glowColor: color,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 46,
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : p.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : p.border, width: selected ? 1.8 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.15 : 1,
                duration: const Duration(milliseconds: 240),
                child: Icon(icon, size: 16, color: selected ? color : p.muted),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? color : p.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowButton extends StatefulWidget {
  const _GlowButton({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    final button = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: on
                ? const [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)]
                : [brandGreen.withValues(alpha: 0.4), brandGreen.withValues(alpha: 0.32)],
          ),
          boxShadow: on
              ? [BoxShadow(color: brandGreen.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 7))]
              : const [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: on ? 0 : -0.1,
              duration: const Duration(milliseconds: 300),
              child: const Icon(LucideIcons.sparkles, size: 19, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(widget.label, style: GoogleFonts.manrope(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: on
          ? HoverLift(radius: 16, scale: 1.02, glowColor: brandGreen, child: ShineSweep(radius: 16, child: button))
          : button,
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.p,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final List<String> items;
  final HomePalette p;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(LucideIcons.map_pin, size: 14, color: brandGreen),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.text)),
            ],
          ),
        ),
        HoverLift(
          radius: 14,
          lift: 2,
          scale: 1.01,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: value != null ? brandGreen.withValues(alpha: 0.6) : p.border, width: value != null ? 1.5 : 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint, style: GoogleFonts.manrope(fontSize: 13, color: p.muted)),
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(LucideIcons.chevron_down, size: 18, color: brandGreen),
                style: GoogleFonts.manrope(fontSize: 13.5, color: p.text, fontWeight: FontWeight.w600),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThinkingView extends StatefulWidget {
  const _ThinkingView({super.key, required this.s, required this.p, required this.pulse});

  final HomeStrings s;
  final HomePalette p;
  final AnimationController pulse;

  @override
  State<_ThinkingView> createState() => _ThinkingViewState();
}

class _ThinkingViewState extends State<_ThinkingView> {
  static const _steps = [
    'Читаю описание проблемы',
    'Определяю категорию и услугу',
    'Ищу лучших мастеров рядом',
  ];
  int _done = 0;

  @override
  void initState() {
    super.initState();
    // Шаги отмечаются по очереди, пока идёт подбор (~2.5 с).
    for (var i = 1; i <= _steps.length; i++) {
      Future<void>.delayed(Duration(milliseconds: 750 * i), () {
        if (mounted) setState(() => _done = i);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: widget.pulse,
            builder: (_, child) => Transform.rotate(
              angle: (widget.pulse.value - 0.5) * 0.3,
              child: child,
            ),
            child: PulseRing(
              color: brandGreen,
              size: 84,
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6DD674), Color(0xFF2E7D32)],
                  ),
                ),
                child: const Icon(LucideIcons.brain_circuit, color: Colors.white, size: 38),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            widget.s.aiThinking,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: p.text, height: 1.4),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (c, a) => ScaleTransition(
                      scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
                      child: c,
                    ),
                    child: i < _done
                        ? const Icon(LucideIcons.circle_check, key: ValueKey('ok'), color: brandGreen, size: 20)
                        : (i == _done
                            ? const SizedBox(
                                key: ValueKey('spin'),
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: brandGreen),
                                ),
                              )
                            : Icon(LucideIcons.circle, key: const ValueKey('wait'), color: p.border, size: 20)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: i <= _done ? FontWeight.w700 : FontWeight.w500,
                        color: i <= _done ? p.text : p.muted,
                      ),
                      child: Text(_steps[i]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({
    super.key,
    required this.s,
    required this.p,
    required this.locale,
    required this.result,
    required this.onChange,
    required this.onAllMasters,
  });

  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final AiMatchResult result;
  final VoidCallback onChange;
  final VoidCallback onAllMasters;

  @override
  Widget build(BuildContext context) {
    final catName = result.category.name(locale);
    final svcName = result.service.name(locale);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            children: [
              Reveal(
                offsetY: 16,
                child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: brandGreen.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: brandGreen.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.circle_check, size: 18, color: brandGreen),
                        const SizedBox(width: 8),
                        Text(s.aiResultTitle, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _InfoTile(label: s.aiResultCategoryLabel, value: catName, p: p)),
                        const SizedBox(width: 8),
                        Expanded(child: _InfoTile(label: s.aiResultServiceLabel, value: svcName, p: p)),
                      ],
                    ),
                    if (result.mayNeedProduct) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: p.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.package, size: 14, color: p.muted),
                            const SizedBox(width: 6),
                            Text(s.aiProductMayNeed, style: GoogleFonts.manrope(fontSize: 11, color: p.muted)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      s.aiSummaryFor(catName),
                      style: GoogleFonts.manrope(fontSize: 11.5, color: p.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(LucideIcons.users, size: 16, color: brandGreen),
                  const SizedBox(width: 6),
                  Text(
                    '${s.aiMastersByCategory} (${result.masters.length})',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (result.masters.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(s.nothingFoundMasters, style: GoogleFonts.manrope(fontSize: 13, color: p.muted)),
                  ),
                )
              else
                ...result.masters.asMap().entries.map(
                  (e) => Reveal(
                    delay: Duration(milliseconds: 150 + 90 * e.key),
                    offsetY: 20,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: HoverLift(
                        radius: 16,
                        scale: 1.015,
                        glowColor: brandGreen,
                        child: _AiMasterCard(
                          master: e.value,
                          s: s,
                          p: p,
                          locale: locale,
                          categoryName: catName,
                          isBest: e.key == 0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.border)),
            color: p.cardBg,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onChange,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.text,
                    side: BorderSide(color: p.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.aiChangeRequest, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onAllMasters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.text,
                    side: BorderSide(color: p.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.aiAllCategoryMasters, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, required this.p});

  final String label;
  final String value;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 10, color: p.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.text, height: 1.15),
          ),
        ],
      ),
    );
  }
}

class _AiMasterCard extends StatelessWidget {
  const _AiMasterCard({
    required this.master,
    required this.s,
    required this.p,
    required this.locale,
    required this.categoryName,
    required this.isBest,
  });

  final MasterItem master;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final String categoryName;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final badges = <String>[
      if (isBest) s.aiBadgeBestChoice,
      if (master.rating >= 4.8) s.aiBadgeHighRating,
      if (master.isTop) s.badgeTop,
    ];

    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            SmoothRoute<void>(builder: (_) => MasterDetailPage(master: master)),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isBest ? brandGreen.withValues(alpha: 0.5) : p.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      master.fullName,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
                    ),
                  ),
                  Text(
                    '${s.fromPrice} ${master.priceMin} ${s.priceUnit}',
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: brandGreen),
                  ),
                ],
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: badges.map((b) => _Badge(label: b, p: p, accent: isBest && b == s.aiBadgeBestChoice)).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.star, size: 13, color: Color(0xFFFFC107)),
                  const SizedBox(width: 3),
                  Text(
                    '${master.rating.toStringAsFixed(1)} (${master.reviews})',
                    style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.text),
                  ),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.clock, size: 12, color: p.muted),
                  const SizedBox(width: 3),
                  Text(
                    '${master.experienceYears} ${s.yearsShort}',
                    style: GoogleFonts.manrope(fontSize: 11, color: p.muted),
                  ),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.map_pin, size: 12, color: p.muted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      master.districts.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(fontSize: 11, color: p.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${s.aiWorksInCategory} «$categoryName»',
                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: brandGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.p, this.accent = false});

  final String label;
  final HomePalette p;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? brandGreen.withValues(alpha: 0.12) : p.searchBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent ? brandGreen.withValues(alpha: 0.35) : p.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent ? brandGreen : p.muted,
        ),
      ),
    );
  }
}
