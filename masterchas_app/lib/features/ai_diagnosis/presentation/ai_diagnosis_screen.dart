import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_design.dart';
import '../../home/presentation/home_palette.dart';
import '../../masters/presentation/masters_page.dart';
import '../data/ai_photo_api.dart';
import '../../../core/widgets/motion.dart';

/// AI диагностика по фото — настоящий ИИ (Claude) через edge-функцию ai-photo-diagnosis, та же что на сайте.
/// Отвечает: что сломано и какой мастер нужен, либо что ничего не сломано.
class AiDiagnosisScreen extends StatefulWidget {
  const AiDiagnosisScreen({super.key});

  @override
  State<AiDiagnosisScreen> createState() => _AiDiagnosisScreenState();
}

enum _Step { intro, analyzing, result, ok, rejected }

class _AiDiagnosisScreenState extends State<AiDiagnosisScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.intro;
  Uint8List? _photo;
  AiRemoteDiagnosis? _diagnosis;
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

    try {
      final result = await AiPhotoApi.diagnose(bytes);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _diagnosis = result;
        switch (result.status) {
          case AiPhotoStatus.broken:
            _step = _Step.result;
          case AiPhotoStatus.ok:
            _step = _Step.ok;
          case AiPhotoStatus.unclear:
            _rejection = result.problemDetail.isNotEmpty
                ? result.problemDetail
                : 'ИИ не смог понять, что на фото. Сфотографируйте поломку ближе и при хорошем свете.';
            _step = _Step.rejected;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AiPhotoException ? e.message : 'Не удалось проанализировать фото. Попробуйте ещё раз.';
        _step = _Step.intro;
        _photo = null;
      });
    }
  }

  void _openMasters() {
    final category = _diagnosis?.masterCategory;
    if (category == null) return;
    Navigator.of(context).push(
      SmoothRoute<void>(
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
                _Step.ok => _buildOk(p),
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
            style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
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
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Трещина, протечка, сгоревшая розетка — ИИ посмотрит на фото, скажет что сломано и какой мастер нужен. А если всё целое — так и скажет.',
                  style: GoogleFonts.manrope(
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
            Text(_error!, style: GoogleFonts.manrope(fontSize: 13, color: AppDesign.accentRed)),
          ],
          const SizedBox(height: 24),
          Text(
            'Что определит AI:',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 14),
          _feature(LucideIcons.search, 'Тип поломки', 'Определит что именно сломано', p),
          const SizedBox(height: 10),
          _feature(LucideIcons.circle_check, 'Всё ли в порядке', 'Скажет, если ничего не сломано', p),
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
                      style: GoogleFonts.manrope(
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

        ],
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
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: p.text),
              ),
              Text(
                sub,
                style: GoogleFonts.manrope(fontSize: 12, color: p.muted),
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
            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Ищем признаки поломки и подбираем мастера',
            style: GoogleFonts.manrope(fontSize: 14, color: p.muted),
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
            style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 10),
          Text(
            _rejection ?? 'Не удалось определить проблему на фото.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 14, color: p.muted, height: 1.45),
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
                          'Анализ готов',
                          style: GoogleFonts.manrope(
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
                      style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(fontSize: 13, color: p.muted, height: 1.4),
          ),
          if (d.advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            _adviceBox(d.advice, p),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _resultStat(LucideIcons.gauge, 'Срочность', d.urgencyLabel, d.urgency == 'high' ? AppDesign.accentRed : AppDesign.accentOrange, p)),
              const SizedBox(width: 12),
              Expanded(child: _resultStat(LucideIcons.wrench, 'Мастер', d.masterCategory, AppDesign.accentBlue, p)),
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
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        d.priceRange,
                        style: GoogleFonts.manrope(
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
            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
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
                        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
                      ),
                      Text(
                        '${d.mastersNearby} мастеров в каталоге',
                        style: GoogleFonts.manrope(fontSize: 12, color: p.muted),
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
                style: GoogleFonts.manrope(
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

  Widget _adviceBox(String text, HomePalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppDesign.accentOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.lightbulb, size: 18, color: AppDesign.accentOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.manrope(fontSize: 13, color: p.text, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildOk(HomePalette p) {
    final d = _diagnosis;
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
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppDesign.brandGradient,
              shape: BoxShape.circle,
              boxShadow: AppDesign.brandGlow(intensity: 0.3),
            ),
            child: const Icon(LucideIcons.circle_check, size: 38, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            (d?.problemTitle.isNotEmpty ?? false) ? d!.problemTitle : 'Ничего не сломано',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 10),
          Text(
            d?.problemDetail ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 14, color: p.muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppDesign.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Мастер не нужен',
              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: AppDesign.brand),
            ),
          ),
          if (d != null && d.advice.isNotEmpty) ...[
            const SizedBox(height: 18),
            _adviceBox(d.advice, p),
          ],
          const SizedBox(height: 14),
          Text(
            'Проблема всё же есть (не включается, шумит, капает)? Сфотографируйте её ещё раз поближе.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 12, color: p.muted, height: 1.4),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Сфотографировать другое',
            icon: LucideIcons.camera,
            gradient: AppDesign.aiGradient,
            glowColor: AppDesign.accentPurple,
            onPressed: () => setState(() {
              _step = _Step.intro;
              _photo = null;
              _diagnosis = null;
            }),
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
            style: GoogleFonts.manrope(fontSize: 11, color: p.muted),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: p.text),
          ),
        ],
      ),
    );
  }
}
