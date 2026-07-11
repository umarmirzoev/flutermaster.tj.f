import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image/image.dart' as img;

import '../../masters/data/masters_data.dart';

/// Результат анализа фото проблемы.
class AiPhotoDiagnosis {
  const AiPhotoDiagnosis({
    required this.problemTitle,
    required this.problemDetail,
    required this.complexity,
    required this.timeEstimate,
    required this.priceMin,
    required this.priceMax,
    required this.masterCategory,
    required this.masterIcon,
    required this.confidence,
  });

  final String problemTitle;
  final String problemDetail;
  final String complexity;
  final String timeEstimate;
  final int priceMin;
  final int priceMax;
  final String masterCategory;
  final IconData masterIcon;
  final int confidence; // 0–100

  String get priceRange => '$priceMin — $priceMax сомони';

  int get mastersNearby => mastersForCategory(masterCategory).length;
}

/// Итог анализа: либо диагноз, либо отказ «не опознано».
class AiPhotoAnalysisResult {
  const AiPhotoAnalysisResult.recognized(this.diagnosis)
      : rejectionMessage = null;

  const AiPhotoAnalysisResult.rejected(this.rejectionMessage) : diagnosis = null;

  final AiPhotoDiagnosis? diagnosis;
  final String? rejectionMessage;

  bool get isRecognized => diagnosis != null;
}

class _ImageFeatures {
  const _ImageFeatures({
    required this.avgR,
    required this.avgG,
    required this.avgB,
    required this.luminanceStd,
    required this.edgeScore,
    required this.blueRatio,
    required this.warmRatio,
    required this.grayRatio,
    required this.greenRatio,
    required this.redRatio,
    required this.darkRatio,
    required this.brightRatio,
    required this.saturationAvg,
  });

  final double avgR;
  final double avgG;
  final double avgB;
  final double luminanceStd;
  final double edgeScore;
  final double blueRatio;
  final double warmRatio;
  final double grayRatio;
  final double greenRatio;
  final double redRatio;
  final double darkRatio;
  final double brightRatio;
  final double saturationAvg;
}

/// Анализирует фото по цвету, яркости и текстуре.
/// Если снимок нечёткий или не похож на поломку — возвращает отказ.
AiPhotoAnalysisResult analyzeRepairPhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const AiPhotoAnalysisResult.rejected(
      'Не опознано: не удалось прочитать фото. Сделайте снимок заново при хорошем освещении.',
    );
  }

  if (bytes.length < 12 * 1024) {
    return const AiPhotoAnalysisResult.rejected(
      'Не опознано: фото слишком маленькое или размытое. Подойдите ближе к проблеме.',
    );
  }

  final resized = img.copyResize(decoded, width: 96);
  final features = _extractFeatures(resized);
  return _classify(features);
}

_ImageFeatures _extractFeatures(img.Image image) {
  final w = image.width;
  final h = image.height;
  var sumR = 0.0;
  var sumG = 0.0;
  var sumB = 0.0;
  var sumLum = 0.0;
  var sumSat = 0.0;
  var edgeSum = 0.0;
  var edgeCount = 0;
  var blue = 0;
  var warm = 0;
  var gray = 0;
  var green = 0;
  var red = 0;
  var dark = 0;
  var bright = 0;
  final luminances = <double>[];

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = image.getPixel(x, y);
      final r = p.r / 255.0;
      final g = p.g / 255.0;
      final b = p.b / 255.0;
      sumR += r;
      sumG += g;
      sumB += b;

      final maxC = max(r, max(g, b));
      final minC = min(r, min(g, b));
      final lum = 0.299 * r + 0.587 * g + 0.114 * b;
      sumLum += lum;
      luminances.add(lum);
      final sat = maxC == 0 ? 0.0 : (maxC - minC) / maxC;
      sumSat += sat;

      if (lum < 0.22) dark++;
      if (lum > 0.78) bright++;

      if (b > r + 0.08 && b > g + 0.05) blue++;
      if (r > g && r > b && r > 0.35) red++;
      if (g > r + 0.05 && g > b + 0.03 && g > 0.28) green++;
      if (r > 0.45 && g > 0.35 && b < 0.35) warm++;
      if (sat < 0.14 && lum > 0.15 && lum < 0.85) gray++;

      if (x > 0 && y > 0) {
        final prev = image.getPixel(x - 1, y);
        final above = image.getPixel(x, y - 1);
        final dr = (p.r - prev.r).abs() + (p.r - above.r).abs();
        final dg = (p.g - prev.g).abs() + (p.g - above.g).abs();
        final db = (p.b - prev.b).abs() + (p.b - above.b).abs();
        edgeSum += (dr + dg + db) / (255.0 * 6);
        edgeCount++;
      }
    }
  }

  final count = w * h;
  final avgLum = sumLum / count;
  var variance = 0.0;
  for (final lum in luminances) {
    variance += pow(lum - avgLum, 2);
  }

  return _ImageFeatures(
    avgR: sumR / count,
    avgG: sumG / count,
    avgB: sumB / count,
    luminanceStd: sqrt(variance / count),
    edgeScore: edgeCount == 0 ? 0 : edgeSum / edgeCount,
    blueRatio: blue / count,
    warmRatio: warm / count,
    grayRatio: gray / count,
    greenRatio: green / count,
    redRatio: red / count,
    darkRatio: dark / count,
    brightRatio: bright / count,
    saturationAvg: sumSat / count,
  );
}

AiPhotoAnalysisResult _classify(_ImageFeatures f) {
  // Слишком тёмный, пересвеченный или «пустой» кадр.
  if (f.luminanceStd < 0.045 && f.edgeScore < 0.06) {
    return const AiPhotoAnalysisResult.rejected(
      'Не опознано: на фото не видно деталей. Сфотографируйте проблему крупнее и при свете.',
    );
  }
  if (f.darkRatio > 0.72 || f.brightRatio > 0.82) {
    return const AiPhotoAnalysisResult.rejected(
      'Не опознано: снимок слишком тёмный или засвеченный. Повторите при нормальном освещении.',
    );
  }
  if (f.edgeScore < 0.045 && f.saturationAvg < 0.12) {
    return const AiPhotoAnalysisResult.rejected(
      'Не опознано: изображение размыто или однотонное. Наведите камеру на поломку.',
    );
  }
  final profiles = <({
    double score,
    String title,
    String detail,
    String complexity,
    String time,
    int priceMin,
    int priceMax,
    String category,
    IconData icon,
  })>[
    (
      score: f.blueRatio * 4.2 +
          (f.avgB > f.avgR ? 0.8 : 0) +
          f.brightRatio * 0.6 +
          (f.saturationAvg < 0.35 ? 0.4 : 0),
      title: 'Протечка или затопление',
      detail: 'На снимке заметны признаки воды или влажности — возможна протечка трубы, крана или стыка.',
      complexity: f.edgeScore > 0.12 ? 'Средняя' : 'Лёгкая',
      time: f.edgeScore > 0.12 ? '~1–2 часа' : '~40–90 мин',
      priceMin: 120,
      priceMax: 320,
      category: 'Сантехника',
      icon: LucideIcons.droplet,
    ),
    (
      score: f.warmRatio * 3.0 +
          f.brightRatio * 1.5 +
          f.redRatio * 2.0 +
          f.edgeScore * 2.2 +
          (f.darkRatio > 0.18 ? 0.9 : 0),
      title: 'Проблема с электрикой',
      detail: 'Похоже на повреждение проводки, розетки или выключателя — возможны искры, перегрев или отсутствие питания.',
      complexity: f.darkRatio > 0.25 ? 'Сложная' : 'Средняя',
      time: f.darkRatio > 0.25 ? '~2–4 часа' : '~1–2 часа',
      priceMin: 150,
      priceMax: 450,
      category: 'Электрика',
      icon: LucideIcons.zap,
    ),
    (
      score: f.grayRatio * 3.5 +
          f.luminanceStd * 4.0 +
          f.edgeScore * 2.5 +
          (f.saturationAvg < 0.22 ? 0.8 : 0),
      title: 'Трещина или повреждение стены',
      detail: 'Видны следы механического повреждения, трещина или отслоение отделки — нужен ремонт поверхности.',
      complexity: f.luminanceStd > 0.16 ? 'Средняя' : 'Лёгкая',
      time: f.luminanceStd > 0.16 ? '~2–5 часов' : '~1–3 часа',
      priceMin: 180,
      priceMax: 600,
      category: 'Отделка',
      icon: LucideIcons.house,
    ),
    (
      score: f.warmRatio * 2.2 +
          f.grayRatio * 1.2 +
          f.edgeScore * 1.8 +
          (f.avgR > 0.38 && f.avgG > 0.28 && f.avgB < 0.32 ? 1.2 : 0),
      title: 'Проблема с дверью или замком',
      detail: 'Снимок похож на дверь, фурнитуру или замок — возможно заклинивание, поломка ручки или петель.',
      complexity: 'Средняя',
      time: '~1–2 часа',
      priceMin: 100,
      priceMax: 280,
      category: 'Мебель и двери',
      icon: LucideIcons.door_open,
    ),
    (
      score: f.redRatio * 2.5 +
          f.warmRatio * 2.0 +
          (f.avgR > f.avgB + 0.08 ? 0.9 : 0) +
          f.darkRatio * 0.8,
      title: 'Неисправность отопления',
      detail: 'Похоже на проблему с радиатором, котлом или обогревом — возможен холод в помещении или утечка теплоносителя.',
      complexity: 'Средняя',
      time: '~2–3 часа',
      priceMin: 200,
      priceMax: 500,
      category: 'Отопление',
      icon: LucideIcons.thermometer,
    ),
    (
      score: f.greenRatio * 4.0 +
          f.darkRatio * 1.5 +
          (f.avgG > f.avgR && f.avgG > f.avgB ? 1.0 : 0),
      title: 'Плесень или повышенная влажность',
      detail: 'На фото видны тёмные или зеленоватые участки — вероятна сырость, плесень или последствия протечки.',
      complexity: 'Средняя',
      time: '~2–4 часа',
      priceMin: 160,
      priceMax: 420,
      category: 'Уборка',
      icon: LucideIcons.spray_can,
    ),
    (
      score: f.saturationAvg * 2.5 +
          f.brightRatio * 1.2 +
          f.edgeScore * 1.0 +
          (f.avgR > 0.4 && f.avgG > 0.35 ? 1.0 : 0),
      title: 'Повреждение покрытия / малярные работы',
      detail: 'Заметны сколы, облупившаяся краска или неровности — потребуется подготовка и покраска поверхности.',
      complexity: 'Лёгкая',
      time: '~3–6 часов',
      priceMin: 140,
      priceMax: 380,
      category: 'Малярные работы',
      icon: LucideIcons.paint_roller,
    ),
    (
      score: f.darkRatio * 2.8 +
          f.grayRatio * 1.5 +
          (f.saturationAvg < 0.18 ? 0.7 : 0) +
          f.edgeScore * 0.8,
      title: 'Засор или неисправность сантехники',
      detail: 'Тёмные участки и низкая насыщенность цвета — возможен засор, неисправность слива или старой арматуры.',
      complexity: f.darkRatio > 0.35 ? 'Сложная' : 'Средняя',
      time: f.darkRatio > 0.35 ? '~2–3 часа' : '~1–2 часа',
      priceMin: 100,
      priceMax: 300,
      category: 'Сантехника',
      icon: LucideIcons.wrench,
    ),
  ];

  profiles.sort((a, b) => b.score.compareTo(a.score));
  final best = profiles.first;
  final second = profiles.length > 1 ? profiles[1].score : 0;
  final gap = best.score - second;

  // Слабый сигнал — не выдаём случайную «услугу».
  if (best.score < 0.55 || gap < 0.18) {
    return const AiPhotoAnalysisResult.rejected(
      'Не опознано: не удалось определить тип поломки. Сфотографируйте проблему ближе и чётче.',
    );
  }

  final confidence = (55 + gap * 18 + best.score * 8).round().clamp(58, 96);

  return AiPhotoAnalysisResult.recognized(
    AiPhotoDiagnosis(
      problemTitle: best.title,
      problemDetail: best.detail,
      complexity: best.complexity,
      timeEstimate: best.time,
      priceMin: best.priceMin,
      priceMax: best.priceMax,
      masterCategory: best.category,
      masterIcon: best.icon,
      confidence: confidence,
    ),
  );
}
