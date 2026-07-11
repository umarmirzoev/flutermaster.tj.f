import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_design.dart';
import '../../home/presentation/home_palette.dart';
import '../../masters/presentation/masters_page.dart';
import '../data/ai_photo_analyzer.dart';

/// AI диагностика по фото — анализ цвета, яркости и текстуры снимка.
class AiDiagnosisScreen extends StatefulWidget {
  const AiDiagnosisScreen({super.key});

  @override
  State<AiDiagnosisScreen> createState() => _AiDiagnosisScreenState();
}

enum _Step { intro, analyzing, result, rejected }

class _AiDiagnosisScreenState extends State<AiDiagnosisScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.intro;
  Uint8List? _photo;
  AiPhotoDiagnosis? _diagnosis;
  String? _rejection;
  String? _error;
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _photo = bytes;
      _diagnosis = null;
      _rejection = null;
      _error = null;
      _step = _Step.analyzing;
    });
    HapticFeedback.mediumImpact();

    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    try {
      final result = analyzeRepairPhoto(bytes);
      HapticFeedback.mediumImpact();
      if (!result.isRecognized) {
        setState(() {
          _rejection = result.rejectionMessage;
          _step = _Step.rejected;
        });
        return;
      }
      setState(() {
        _diagnosis = result.diagnosis;
        _step = _Step.result;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка анализа: $e';
        _step = _Step.intro;
        _photo = null;
      });
    }
  }

  void _openMasters() {
    final category = _diagnosis?.masterCategory;
    if (category == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MastersPage(initialFilter: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(p),
            Expanded(
              child: switch (_step) {
                _Step.intro => _buildIntro(p),
                _Step.analyzing => _buildAnalyzing(p),
                _Step.result => _buildResult(p),
                _Step.rejected => _buildRejected(p),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(HomePalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(LucideIcons.arrow_left, color: p.text),
          ),
          Text(
            'AI диагностика',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: p.text,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppDesign.aiGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'AI',
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
    );
  }

  Widget _buildIntro(HomePalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppDesign.aiGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppDesign.glowShadow(AppDesign.accentPurple),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.scan_eye, color: Colors.white, size: 34),
                const SizedBox(height: 12),
                Text(
                  'Сфотографируйте проблему —\nAI подскажет решение',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Трещина, поломка, протечка — AI проанализирует фото и определит тип поломки и нужного мастера',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppDesign.accentRed)),
          ],
          const SizedBox(height: 24),
          Text(
            'Что определит AI:',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 14),
          _feature(LucideIcons.search, 'Тип поломки', 'Определит что именно сломано', p),
          const SizedBox(height: 10),
          _feature(LucideIcons.gauge, 'Сложность', 'Оценит масштаб работы', p),
          const SizedBox(height: 10),
          _feature(LucideIcons.users, 'Нужный мастер', 'Подберёт категорию специалиста', p),
          const SizedBox(height: 10),
          _feature(LucideIcons.wallet, 'Примерная цена', 'Рассчитает бюджет заранее', p),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Сфотографировать',
            icon: LucideIcons.camera,
            gradient: AppDesign.aiGradient,
            glowColor: AppDesign.accentPurple,
            onPressed: () => _pickPhoto(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pickPhoto(ImageSource.gallery),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: p.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.border),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.image, size: 18, color: p.text),
                    const SizedBox(width: 8),
                    Text(
                      'Выбрать из галереи',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _adminLinks(p),
        ],
      ),
    );
  }

  Widget _adminLinks(HomePalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Кабинеты управления',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Вход для администраторов платформы',
            style: GoogleFonts.inter(fontSize: 12, color: p.muted),
          ),
          const SizedBox(height: 12),
          _adminLinkTile(
            p: p,
            icon: LucideIcons.shield,
            title: 'Админ-панель',
            sub: '/admin/login',
            onTap: () => context.go('/admin/login'),
          ),
          const SizedBox(height: 8),
          _adminLinkTile(
            p: p,
            icon: LucideIcons.crown,
            title: 'Супер-админ',
            sub: '/superadmin/dashboard',
            onTap: () => context.go('/superadmin/dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _adminLinkTile({
    required HomePalette p,
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Material(
      color: p.pageBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppDesign.accentPurple),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
                    Text(sub, style: GoogleFonts.inter(fontSize: 11, color: p.muted)),
                  ],
                ),
              ),
              Icon(LucideIcons.external_link, size: 16, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String title, String sub, HomePalette p) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppDesign.accentPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppDesign.accentPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
              ),
              Text(
                sub,
                style: GoogleFonts.inter(fontSize: 12, color: p.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzing(HomePalette p) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _photo != null
                    ? Image.memory(_photo!, width: 280, height: 280, fit: BoxFit.cover)
                    : Container(width: 280, height: 280, color: p.cardBg),
              ),
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  return Positioned(
                    top: 20 + _scanController.value * 240,
                    child: Container(
                      width: 280,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppDesign.accentPurple.withValues(alpha: 0),
                            AppDesign.brandLight,
                            AppDesign.accentPurple.withValues(alpha: 0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppDesign.brandLight.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppDesign.accentPurple.withValues(alpha: 0.5), width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            'AI анализирует фото...',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Считываем цвет, текстуру и признаки поломки',
            style: GoogleFonts.inter(fontSize: 14, color: p.muted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: p.border,
                valueColor: const AlwaysStoppedAnimation(AppDesign.accentPurple),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejected(HomePalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(_photo!, width: 220, height: 220, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppDesign.accentRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.circle_x, size: 36, color: AppDesign.accentRed),
          ),
          const SizedBox(height: 16),
          Text(
            'Не опознано',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 10),
          Text(
            _rejection ?? 'Не удалось определить проблему на фото.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: p.muted, height: 1.45),
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Сфотографировать заново',
            icon: LucideIcons.camera,
            gradient: AppDesign.aiGradient,
            glowColor: AppDesign.accentPurple,
            onPressed: () => setState(() {
              _step = _Step.intro;
              _photo = null;
              _rejection = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(HomePalette p) {
    final d = _diagnosis;
    if (d == null) return const SizedBox.shrink();

    final masterLabel = d.masterCategory == 'Электрика'
        ? 'электрика'
        : d.masterCategory == 'Сантехника'
            ? 'сантехника'
            : d.masterCategory.toLowerCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(_photo!, width: 80, height: 80, fit: BoxFit.cover),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.circle_check, size: 18, color: AppDesign.brand),
                        const SizedBox(width: 6),
                        Text(
                          'Анализ готов · ${d.confidence}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppDesign.brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.problemTitle,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            d.problemDetail,
            style: GoogleFonts.inter(fontSize: 13, color: p.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _resultStat(LucideIcons.gauge, 'Сложность', d.complexity, AppDesign.accentOrange, p)),
              const SizedBox(width: 12),
              Expanded(child: _resultStat(LucideIcons.clock, 'Время', d.timeEstimate, AppDesign.accentBlue, p)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppDesign.brandGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppDesign.brandGlow(intensity: 0.2),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.wallet, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Примерная стоимость',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        d.priceRange,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Рекомендуемый мастер:',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppDesign.brand.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppDesign.accentBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(d.masterIcon, color: AppDesign.accentBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.masterCategory,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                      ),
                      Text(
                        '${d.mastersNearby} мастеров в каталоге',
                        style: GoogleFonts.inter(fontSize: 12, color: p.muted),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevron_right, size: 20, color: p.muted),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Найти $masterLabel',
            icon: LucideIcons.search,
            onPressed: _openMasters,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _step = _Step.intro;
                _photo = null;
                _diagnosis = null;
              }),
              child: Text(
                'Сфотографировать заново',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultStat(IconData icon, String label, String value, Color color, HomePalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: p.muted),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
          ),
        ],
      ),
    );
  }
}
