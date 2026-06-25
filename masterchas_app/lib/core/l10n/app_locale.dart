enum AppLocale {
  ru('ru', 'Русский'),
  en('en', 'English'),
  tg('tg', 'Тоҷикӣ'),
  zh('zh', '中文');

  const AppLocale(this.code, this.label);
  final String code;
  final String label;
}
