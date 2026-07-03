import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/providers/locale_provider.dart';
import '../../services/data/service_catalog_keys.dart';
import '../../services/data/services_catalog.dart';
import '../providers/auth_provider.dart';
import '../providers/master_registration_draft_provider.dart';

const _navy = Color(0xFF1C2438);
const _bodyGrey = Color(0xFF6B7280);
const _titleColor = Color(0xFF111827);
const _pageBg = Color(0xFFF8FAFC);
const _brandGreen = Color(0xFF57B55E);

class MasterSkillsScreen extends ConsumerStatefulWidget {
  const MasterSkillsScreen({super.key});

  @override
  ConsumerState<MasterSkillsScreen> createState() => _MasterSkillsScreenState();
}

class _MasterSkillsScreenState extends ConsumerState<MasterSkillsScreen> {
  int? _expandedIndex;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final draft = ref.read(masterRegistrationDraftProvider);
    if (draft.hasProfile) return;

    final saved = await ref.read(authProvider.notifier).readSavedMasterProfile();
    if (!mounted) return;
    if (saved == null) {
      context.go('/master/register');
      return;
    }

    ref.read(masterRegistrationDraftProvider.notifier).saveProfile(
          lastName: saved.lastName,
          firstName: saved.firstName,
          patronymic: saved.patronymic,
          isSelfEmployed: saved.isSelfEmployed,
          companyName: saved.companyName,
        );
    ref
        .read(masterRegistrationDraftProvider.notifier)
        .setSelectedServices(saved.selectedServices.toSet());
  }

  Future<void> _onContinue() async {
    final draft = ref.read(masterRegistrationDraftProvider);
    if (draft.selectedServices.isEmpty || _isSubmitting) return;

    if (!draft.hasProfile) {
      context.go('/master/register');
      return;
    }

    if (mounted) context.go('/master/photo');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final draft = ref.watch(masterRegistrationDraftProvider);
    final selectedCount = draft.selectedServices.length;
    final canContinue = selectedCount > 0 && !_isSubmitting;

    if (!draft.hasProfile) {
      return const Scaffold(
        backgroundColor: _pageBg,
        body: Center(child: CircularProgressIndicator(color: _brandGreen)),
      );
    }

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/master/register'),
                    icon: const Icon(LucideIcons.arrow_left, color: _titleColor),
                  ),
                  Text(
                    'master.tj',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Text(
                    'Чем вы занимаетесь?',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Укажите все ваши навыки и специальности, чтобы вам '
                    'поступало больше подходящих заказов.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _bodyGrey,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...List.generate(serviceCatalog.length, (index) {
                    final category = serviceCatalog[index];
                    final isExpanded = _expandedIndex == index;
                    final categorySelected =
                        selectedCountInCategory(category, draft.selectedServices);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CategoryCard(
                        category: category,
                        locale: locale,
                        isExpanded: isExpanded,
                        selectedServices: draft.selectedServices,
                        selectedInCategory: categorySelected,
                        onHeaderTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                        onServiceToggle: (key) {
                          ref
                              .read(masterRegistrationDraftProvider.notifier)
                              .toggleService(key);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedCount > 0)
                    Text(
                      'Выбрано услуг: $selectedCount',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _brandGreen,
                      ),
                    ),
                  if (selectedCount > 0) const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: canContinue ? _onContinue : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        disabledBackgroundColor: _navy.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isSubmitting ? 'Сохранение...' : 'Продолжить',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.locale,
    required this.isExpanded,
    required this.selectedServices,
    required this.selectedInCategory,
    required this.onHeaderTap,
    required this.onServiceToggle,
  });

  final ServiceCategory category;
  final AppLocale locale;
  final bool isExpanded;
  final Set<String> selectedServices;
  final int selectedInCategory;
  final VoidCallback onHeaderTap;
  final ValueChanged<String> onServiceToggle;

  @override
  Widget build(BuildContext context) {
    final accent = category.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? accent.withValues(alpha: 0.45)
              : const Color(0xFFE8ECF1),
          width: isExpanded ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isExpanded ? 0.12 : 0.05),
            blurRadius: isExpanded ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onHeaderTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(category.icon, color: accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name(locale),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _titleColor,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (selectedInCategory > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _brandGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$selectedInCategory',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _brandGreen,
                            ),
                          ),
                        ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          LucideIcons.chevron_down,
                          size: 20,
                          color: _bodyGrey.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                color: accent.withValues(alpha: 0.06),
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(
                  children: [
                    for (final service in category.services)
                      _ServiceCheckTile(
                        label: service.name(locale),
                        isSelected: selectedServices.contains(
                          serviceSelectionKey(category, service),
                        ),
                        accent: accent,
                        onTap: () => onServiceToggle(
                          serviceSelectionKey(category, service),
                        ),
                      ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCheckTile extends StatelessWidget {
  const _ServiceCheckTile({
    required this.label,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? _navy : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? _navy : const Color(0xFFCBD5E1),
                    width: 1.6,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: _titleColor,
                    height: 1.3,
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
