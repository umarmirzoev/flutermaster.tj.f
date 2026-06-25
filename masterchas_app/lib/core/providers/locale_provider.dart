import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';

final localeProvider = NotifierProvider<LocaleNotifier, AppLocale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() => AppLocale.ru;

  void setLocale(AppLocale locale) => state = locale;

  Locale get materialLocale => switch (state) {
        AppLocale.ru => const Locale('ru'),
        AppLocale.en => const Locale('en'),
        AppLocale.tg => const Locale('tg'),
        AppLocale.zh => const Locale('zh'),
      };
}
