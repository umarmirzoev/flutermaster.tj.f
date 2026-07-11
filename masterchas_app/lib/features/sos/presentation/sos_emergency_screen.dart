import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_design.dart';
import '../../masters/data/masters_data.dart';
import '../../masters/presentation/master_detail_page.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOS — Экстренный вызов мастера
/// Одна кнопка → заявка всем ближайшим мастерам с пометкой «СРОЧНО».
/// ═══════════════════════════════════════════════════════════════════════════

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _searchController;

  int? _selectedType;
  bool _searching = false;
  bool _searchDone = false;
  int _mastersFound = 0;
  List<MasterItem> _foundMasters = [];

  static const _emergencyTypes = [
    (LucideIcons.droplets, 'Затопление', 'Прорыв трубы, потоп', Color(0xFF3B82F6)),
    (LucideIcons.zap, 'Нет света', 'Авария электрики', Color(0xFFF59E0B)),
    (LucideIcons.flame, 'Утечка газа', 'Запах газа', Color(0xFFEF4444)),
    (LucideIcons.lock, 'Захлопнулась дверь', 'Не могу попасть домой', Color(0xFF8B5CF6)),
    (LucideIcons.thermometer, 'Нет отопления', 'Холодно в квартире', Color(0xFF14B8A6)),
    (LucideIcons.wrench, 'Другое', 'Срочная проблема', Color(0xFF6B7280)),
  ];

  static const _categoryByType = [
    'Сантехника',
    'Электрика',
    'Сантехника',
    'Мебель и двери',
    'Отопление',
    'Аварийные 24/7',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _triggerSos() async {
    if (_selectedType == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Сначала выберите тип проблемы',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: AppDesign.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.heavyImpact();

    final category = _categoryByType[_selectedType!];
    var list = mastersForCategory(category);
    if (list.isEmpty) {
      list = masters.where((m) => m.isOnline).toList();
    }
    list.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      if (a.isTop != b.isTop) return a.isTop ? -1 : 1;
      return b.rating.compareTo(a.rating);
    });
    final matches = list.take(4).toList();

    setState(() {
      _searching = true;
      _searchDone = false;
      _mastersFound = 0;
      _foundMasters = [];
    });
    _searchController.forward(from: 0);

    if (matches.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() {
        _mastersFound = 0;
        _searchDone = true;
      });
      return;
    }

    for (int i = 0; i < matches.length; i++) {
      await Future.delayed(Duration(milliseconds: 500 + i * 250));
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _mastersFound = i + 1;
        _foundMasters = matches.take(i + 1).toList();
        _searchDone = i == matches.length - 1;
      });
    }
  }

  void _openMasterPicker() {
    if (_foundMasters.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1F1212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Выберите мастера',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Срочный вызов — мастер приедет в ближайшее время',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 16),
              ..._foundMasters.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MasterDetailPage(master: m),
                        ),
                      );
                    },
                    tileColor: Colors.white.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppDesign.brand.withValues(alpha: 0.3)),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppDesign.brand.withValues(alpha: 0.2),
                      child: const Icon(LucideIcons.user, color: AppDesign.brand, size: 18),
                    ),
                    title: Text(
                      m.fullName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      '${m.rating} ★ · от ${m.priceMin} сом',
                      style: GoogleFonts.inter(fontSize: 12, color: AppDesign.brandLight),
                    ),
                    trailing: const Icon(LucideIcons.chevron_right, color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelSearch() {
    setState(() {
      _searching = false;
      _searchDone = false;
      _mastersFound = 0;
      _foundMasters = [];
    });
    _searchController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(LucideIcons.arrow_left, color: Colors.white),
                  ),
                  Text(
                    'Экстренный вызов',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppDesign.accentRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppDesign.accentRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppDesign.accentRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '24/7',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _searching ? _buildSearching() : _buildSelection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Что случилось?',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Выберите проблему — мы найдём ближайшего мастера за минуты',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // ── Emergency type grid ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: _emergencyTypes.length,
            itemBuilder: (context, i) {
              final (icon, title, sub, color) = _emergencyTypes[i];
              final selected = _selectedType == i;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedType = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? color : Colors.white.withValues(alpha: 0.1),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16)]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Big SOS button ──
          Center(
            child: GestureDetector(
              onTap: _triggerSos,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse = _pulseController.value;
                  return Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppDesign.sosGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppDesign.accentRed.withValues(alpha: 0.4 + pulse * 0.3),
                          blurRadius: 30 + pulse * 30,
                          spreadRadius: 5 + pulse * 20,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.siren, color: Colors.white, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'SOS',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Вызвать сейчас',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Первый принявший мастер получает +20% бонус',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearching() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (int ring = 0; ring < 3; ring++) _radarRing(ring),
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppDesign.sosGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppDesign.accentRed.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(LucideIcons.siren, color: Colors.white, size: 36),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  _mastersFound == 0
                      ? 'Ищем мастеров рядом...'
                      : 'Мастера откликаются!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _mastersFound == 0 && _searchDone
                      ? 'Свободных мастеров не найдено. Попробуйте другой тип.'
                      : _mastersFound == 0
                          ? 'Отправляем сигнал всем ближайшим'
                          : 'Найдено мастеров: $_mastersFound',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                if (_foundMasters.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: _foundMasters.length,
                    itemBuilder: (context, i) => _foundMasterChip(_foundMasters[i], i),
                  ),
                ],
                const SizedBox(height: 24),
                if (_foundMasters.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: 'Выбрать мастера',
                      icon: LucideIcons.check,
                      onPressed: _openMasterPicker,
                    ),
                  )
                else if (_searchDone && _foundMasters.isEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      label: 'Попробовать снова',
                      icon: LucideIcons.refresh_cw,
                      onPressed: _cancelSearch,
                    ),
                  )
                else
                  TextButton(
                    onPressed: _cancelSearch,
                    child: Text(
                      'Отменить',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _radarRing(int index) {
    final progress = (_pulseController.value + index / 3) % 1.0;
    return Container(
      width: 100 + progress * 140,
      height: 100 + progress * 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppDesign.accentRed.withValues(alpha: (1 - progress) * 0.5),
          width: 2,
        ),
      ),
    );
  }

  Widget _foundMasterChip(MasterItem master, int i) {
    final mins = [3, 5, 7, 8];
    final shortName = master.fullName.split(' ').length > 1
        ? '${master.fullName.split(' ').first} ${master.fullName.split(' ')[1][0]}.'
        : master.fullName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppDesign.brand.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppDesign.brandGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.user, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shortName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${mins[i % mins.length]} мин · рядом',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppDesign.brandLight,
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
