import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../storage/secure_storage_provider.dart';
import '../storage/secure_storage_service.dart';

final localeProvider = NotifierProvider<LocaleNotifier, AppLocale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    Future.microtask(_load);
    return AppLocale.ru;
  }

  /// Язык сохраняется на устройстве и не сбрасывается при выходе из аккаунта.
  Future<void> _load() async {
    try {
      final saved = await ref
          .read(secureStorageProvider)
          .readSetting(SecureStorageService.localeKey)
          .timeout(const Duration(seconds: 2));
      for (final l in AppLocale.values) {
        if (l.code == saved) state = l;
      }
    } catch (_) {}
  }

  void setLocale(AppLocale locale) {
    state = locale;
    ref.read(secureStorageProvider).writeSetting(SecureStorageService.localeKey, locale.code).catchError((_) {});
  }

  Locale get materialLocale => switch (state) {
        AppLocale.ru => const Locale('ru'),
        AppLocale.en => const Locale('en'),
        AppLocale.tg => const Locale('tg'),
        AppLocale.zh => const Locale('zh'),
      };
}
