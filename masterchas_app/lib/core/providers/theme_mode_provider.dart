import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_provider.dart';
import '../storage/secure_storage_service.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Тема приложения. Выбор сохраняется на устройстве и не сбрасывается при выходе из аккаунта.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future.microtask(_load);
    return ThemeMode.light;
  }

  Future<void> _load() async {
    try {
      final saved = await ref
          .read(secureStorageProvider)
          .readSetting(SecureStorageService.themeModeKey)
          .timeout(const Duration(seconds: 2));
      if (saved == 'dark') state = ThemeMode.dark;
      if (saved == 'light') state = ThemeMode.light;
    } catch (_) {}
  }

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _save();
  }

  Future<void> _save() async {
    try {
      await ref.read(secureStorageProvider).writeSetting(
            SecureStorageService.themeModeKey,
            state == ThemeMode.dark ? 'dark' : 'light',
          );
    } catch (_) {}
  }
}
