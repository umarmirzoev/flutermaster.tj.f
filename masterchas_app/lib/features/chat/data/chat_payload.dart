import 'dart:convert';

import '../../../core/config/app_config.dart';

/// Типы сообщений — совпадают с MessageType на сервере.
abstract final class ChatMessageType {
  static const text = 1;
  static const image = 2;
  static const file = 3;
  static const system = 4;
  static const location = 5;
  static const voice = 6;
}

/// Вложение (фото или файл), загруженное на сервер.
class ChatAttachment {
  const ChatAttachment({
    required this.url,
    required this.fileName,
    required this.contentType,
    required this.size,
    this.durationMs = 0,
  });

  final String url;
  final String fileName;
  final String contentType;
  final int size;

  /// Длительность голосового сообщения (мс). 0 — для фото и файлов.
  final int durationMs;

  String get durationLabel {
    final total = (durationMs / 1000).round();
    final m = total ~/ 60;
    final sec = total % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  /// Полная ссылка для открытия/показа: сервер отдаёт путь вида /api/chat-files/xxx.jpg.
  String get absoluteUrl => chatAbsoluteUrl(url);

  String get sizeLabel {
    if (size >= 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} МБ';
    if (size >= 1024) return '${(size / 1024).toStringAsFixed(0)} КБ';
    return '$size Б';
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'fileName': fileName,
        'contentType': contentType,
        'size': size,
        if (durationMs > 0) 'durationMs': durationMs,
      };

  ChatAttachment copyWith({int? durationMs}) => ChatAttachment(
        url: url,
        fileName: fileName,
        contentType: contentType,
        size: size,
        durationMs: durationMs ?? this.durationMs,
      );

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        url: json['url']?.toString() ?? '',
        fileName: json['fileName']?.toString() ?? 'Файл',
        contentType: json['contentType']?.toString() ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      );

  static ChatAttachment? tryParse(String text) {
    try {
      final json = jsonDecode(text);
      if (json is Map<String, dynamic> && json['url'] != null) {
        return ChatAttachment.fromJson(json);
      }
    } catch (_) {}
    return null;
  }
}

/// Геопозиция, отправленная в чат.
class ChatLocation {
  const ChatLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;

  String get mapsUrl => 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  String toPayload() => jsonEncode({'lat': lat, 'lng': lng});

  static ChatLocation? tryParse(String text) {
    try {
      final json = jsonDecode(text);
      if (json is Map && json['lat'] != null && json['lng'] != null) {
        return ChatLocation(
          lat: (json['lat'] as num).toDouble(),
          lng: (json['lng'] as num).toDouble(),
        );
      }
    } catch (_) {}
    return null;
  }
}

/// MIME-тип по расширению файла.
String chatMimeTypeFor(String fileName) {
  final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'm4a' || 'mp4a' => 'audio/mp4',
    'aac' => 'audio/aac',
    'mp3' => 'audio/mpeg',
    'ogg' || 'opus' => 'audio/ogg',
    'webm' => 'audio/webm',
    'wav' => 'audio/wav',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}

String chatAbsoluteUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = AppConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return '$base${url.startsWith('/') ? '' : '/'}$url';
}

/// Короткая подпись для списка чатов.
String chatPreviewText(int? messageType, String? text) {
  return switch (messageType) {
    ChatMessageType.image => '📷 Фото',
    ChatMessageType.file =>
      '📎 ${ChatAttachment.tryParse(text ?? '')?.fileName ?? 'Файл'}',
    ChatMessageType.location => '📍 Геолокация',
    ChatMessageType.voice => '🎤 Голосовое сообщение',
    _ => (text ?? '').trim(),
  };
}
