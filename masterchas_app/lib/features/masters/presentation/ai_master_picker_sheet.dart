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
          content: Text(s.aiEnterProblem, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
      MaterialPageRoute<void>(
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
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
        gradient: LinearGradient(
          colors: [
            brandGreen.withValues(alpha: 0.08),
            p.cardBg,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4BAF50), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: brandGreen.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(LucideIcons.brain_circuit, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.aiModalTitle,
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: p.text),
                ),
                const SizedBox(height: 3),
                Text(
                  s.aiModalSub,
                  style: GoogleFonts.inter(fontSize: 11.5, color: p.muted, height: 1.35),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(LucideIcons.x, size: 20, color: p.muted),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.aiDescribeLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 8),
          TextField(
            controller: problemController,
            maxLines: 4,
            minLines: 3,
            cursorColor: brandGreen,
            style: GoogleFonts.inter(fontSize: 13, color: p.text, height: 1.4),
            decoration: InputDecoration(
              hintText: s.aiDescribeHint,
              hintStyle: GoogleFonts.inter(fontSize: 12.5, color: p.muted, height: 1.35),
              filled: true,
              fillColor: p.searchBg,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: brandGreen.withValues(alpha: 0.45)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: brandGreen.withValues(alpha: 0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: brandGreen, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.aiDescribeHelper,
            style: GoogleFonts.inter(fontSize: 10.5, color: p.muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _DropdownField(
                label: s.aiDistrictLabel,
                value: district,
                hint: s.aiDistrictHint,
                items: [s.aiDistrictAny, ...masterDistricts],
                p: p,
                onChanged: onDistrict,
              )),
              const SizedBox(width: 8),
              Expanded(child: _DropdownField(
                label: s.aiUrgencyLabel,
                value: urgency == 'urgent' ? s.aiUrgencyUrgent : s.aiUrgencyNormal,
                hint: s.aiUrgencyNormal,
                items: [s.aiUrgencyNormal, s.aiUrgencyUrgent],
                p: p,
                onChanged: (v) => onUrgency(v == s.aiUrgencyUrgent ? 'urgent' : 'normal'),
              )),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.aiBudgetLabel, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: p.muted)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      cursorColor: brandGreen,
                      style: GoogleFonts.inter(fontSize: 12, color: p.text),
                      decoration: InputDecoration(
                        hintText: s.aiBudgetHint,
                        hintStyle: GoogleFonts.inter(fontSize: 11, color: p.muted),
                        isDense: true,
                        filled: true,
                        fillColor: p.searchBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: p.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: p.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(LucideIcons.sparkles, size: 18),
              label: Text(s.aiPickBtn, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
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
        Text(label, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: p.muted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: p.searchBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: GoogleFonts.inter(fontSize: 11, color: p.muted)),
              isExpanded: true,
              icon: Icon(LucideIcons.chevron_down, size: 16, color: p.muted),
              style: GoogleFonts.inter(fontSize: 11.5, color: p.text),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThinkingView extends StatelessWidget {
  const _ThinkingView({super.key, required this.s, required this.p, required this.pulse});

  final HomeStrings s;
  final HomePalette p;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) {
              final scale = 0.92 + pulse.value * 0.08;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        brandGreen.withValues(alpha: 0.2 + pulse.value * 0.15),
                        brandGreen.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const Icon(LucideIcons.sparkles, color: brandGreen, size: 32),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            s.aiThinking,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: p.text, height: 1.4),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: brandGreen),
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
              Container(
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
                        Text(s.aiResultTitle, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
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
                            Text(s.aiProductMayNeed, style: GoogleFonts.inter(fontSize: 11, color: p.muted)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      s.aiSummaryFor(catName),
                      style: GoogleFonts.inter(fontSize: 11.5, color: p.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(LucideIcons.users, size: 16, color: brandGreen),
                  const SizedBox(width: 6),
                  Text(
                    '${s.aiMastersByCategory} (${result.masters.length})',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (result.masters.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(s.nothingFoundMasters, style: GoogleFonts.inter(fontSize: 13, color: p.muted)),
                  ),
                )
              else
                ...result.masters.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
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
                  child: Text(s.aiChangeRequest, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
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
                  child: Text(s.aiAllCategoryMasters, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
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
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: p.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.text, height: 1.15),
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
            MaterialPageRoute<void>(builder: (_) => MasterDetailPage(master: master)),
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
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
                    ),
                  ),
                  Text(
                    '${s.fromPrice} ${master.priceMin} ${s.priceUnit}',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: brandGreen),
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
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.text),
                  ),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.clock, size: 12, color: p.muted),
                  const SizedBox(width: 3),
                  Text(
                    '${master.experienceYears} ${s.yearsShort}',
                    style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                  ),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.map_pin, size: 12, color: p.muted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      master.districts.first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${s.aiWorksInCategory} «$categoryName»',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: brandGreen),
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
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent ? brandGreen : p.muted,
        ),
      ),
    );
  }
}
