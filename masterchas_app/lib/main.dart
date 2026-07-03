import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/l10n/app_locale.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const ProviderScope(child: MasterChasApp()));
}

class MasterChasApp extends ConsumerWidget {
  const MasterChasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Master.tj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // The UI language is driven by our own [localeProvider]/[HomeStrings].
      // Flutter's Material/Cupertino localizations don't support Tajik, so we
      // map it to Russian just for the built-in widget strings (e.g. TextField).
      locale: switch (locale) {
        AppLocale.ru || AppLocale.tg => const Locale('ru'),
        AppLocale.en => const Locale('en'),
        AppLocale.zh => const Locale('zh'),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
        Locale('zh'),
      ],
      routerConfig: router,
    );
  }
}
