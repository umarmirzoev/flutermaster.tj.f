import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../masters/data/masters_data.dart';

/// Что ИИ увидел на фото.
enum AiPhotoStatus { broken, ok, unclear }

/// Ответ настоящего ИИ (Claude) из edge-функции ai-photo-diagnosis — та же, что на сайте.
class AiRemoteDiagnosis {
  const AiRemoteDiagnosis({
    required this.status,
    required this.problemTitle,
    required this.problemDetail,
    required this.masterCategory,
    required this.urgency,
    required this.priceMin,
    required this.priceMax,
    required this.advice,
  });

  final AiPhotoStatus status;
  final String problemTitle;
  final String problemDetail;
  final String masterCategory;
  final String? urgency; // low | medium | high
  final int? priceMin;
  final int? priceMax;
  final String advice;

  factory AiRemoteDiagnosis.fromJson(Map<String, dynamic> j) {
    final s = j['status'] as String? ?? (j['recognized'] == true ? 'broken' : 'unclear');
    int? toInt(dynamic v) => v is num ? v.round() : null;
    return AiRemoteDiagnosis(
      status: s == 'broken'
          ? AiPhotoStatus.broken
          : s == 'ok'
              ? AiPhotoStatus.ok
              : AiPhotoStatus.unclear,
      problemTitle: (j['problem'] as String?) ?? '',
      problemDetail: (j['details'] as String?) ?? '',
      masterCategory: (j['category'] as String?) ?? 'Другие услуги',
      urgency: j['urgency'] as String?,
      priceMin: toInt(j['priceMin']),
      priceMax: toInt(j['priceMax']),
      advice: (j['advice'] as String?) ?? '',
    );
  }

  String get priceRange =>
      priceMin != null && priceMax != null ? '$priceMin — $priceMax сомони' : 'Цену назовёт мастер';

  String get urgencyLabel => switch (urgency) {
        'high' => 'Срочно!',
        'low' => 'Не срочно',
        _ => 'Лучше сегодня',
      };

  IconData get masterIcon {
    final c = masterCategory;
    if (c.contains('Электр')) return LucideIcons.zap;
    if (c.contains('Сантех')) return LucideIcons.droplet;
    if (c.contains('Кондицион')) return LucideIcons.wind;
    if (c.contains('Отоплен')) return LucideIcons.flame;
    if (c.contains('Мебель')) return LucideIcons.armchair;
    if (c.contains('Видео')) return LucideIcons.cctv;
    if (c.contains('Уборк')) return LucideIcons.sparkles;
    if (c.contains('Маляр') || c.contains('Отделк')) return LucideIcons.paint_roller;
    return LucideIcons.wrench;
  }

  int get mastersNearby => mastersForCategory(masterCategory).length;
}

class AiPhotoException implements Exception {
  const AiPhotoException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AiPhotoApi {
  /// Определяем тип картинки по первым байтам (Claude принимает jpeg/png/webp/gif).
  static String _mediaType(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length > 12 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return 'image/webp';
    if (b.length > 3 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return 'image/gif';
    return 'image/jpeg';
  }

  static Future<AiRemoteDiagnosis> diagnose(
    Uint8List bytes, {
    String note = '',
    String language = 'ru',
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ));
    try {
      final res = await dio.post<dynamic>(
        '${AppConfig.supabaseUrl}/functions/v1/ai-photo-diagnosis',
        data: {
          'image': base64Encode(bytes),
          'mediaType': _mediaType(bytes),
          'note': note,
          'language': language,
        },
        options: Options(headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        }),
      );
      final body = res.data is String ? jsonDecode(res.data as String) : res.data;
      final d = (body as Map?)?['diagnosis'];
      if (d is! Map) throw const AiPhotoException('Пустой ответ от ИИ. Попробуйте ещё раз.');
      return AiRemoteDiagnosis.fromJson(Map<String, dynamic>.from(d));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      final reason = data is Map ? data['reason'] : null;
      if (code == 503) throw const AiPhotoException('ИИ пока не подключён на сервере.');
      if (code == 413) throw const AiPhotoException('Фото слишком большое. Попробуйте другое.');
      if (reason == 'no_credits') throw const AiPhotoException('ИИ временно недоступен. Попробуйте позже.');
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AiPhotoException('Нет связи с сервером. Проверьте интернет.');
      }
      throw const AiPhotoException('Не удалось проанализировать фото. Попробуйте ещё раз.');
    }
  }
}
