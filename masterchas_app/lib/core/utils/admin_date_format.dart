/// Формат даты для админ-панели: день.месяц.год часы:минуты
String formatAdminDateTime(DateTime date) {
  final d = '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
  final t = '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
  return '$d $t';
}

String formatAdminDateTimeFromRaw(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return formatAdminDateTime(parsed);

  // Уже в формате DD.MM.YYYY или DD.MM.YYYY HH:mm
  if (RegExp(r'^\d{2}\.\d{2}\.\d{4}').hasMatch(raw)) return raw;
  return raw;
}
