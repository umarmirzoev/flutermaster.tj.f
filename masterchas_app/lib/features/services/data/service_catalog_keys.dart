import 'services_catalog.dart';

String serviceSelectionKey(ServiceCategory category, ServiceItem service) =>
    '${category.ru}::${service.ru}';

int selectedCountInCategory(
  ServiceCategory category,
  Set<String> selected,
) {
  return category.services
      .where((s) => selected.contains(serviceSelectionKey(category, s)))
      .length;
}

/// Находит услугу в каталоге по ключу `Категория::Услуга`.
({ServiceCategory category, ServiceItem service})? lookupServiceByKey(
  String key,
) {
  final parts = key.split('::');
  if (parts.length != 2) return null;

  final categoryRu = parts[0];
  final serviceRu = parts[1];

  for (final category in serviceCatalog) {
    if (category.ru != categoryRu) continue;
    for (final service in category.services) {
      if (service.ru == serviceRu) {
        return (category: category, service: service);
      }
    }
  }
  return null;
}

/// Средняя цена из каталога или 0, если услуга не найдена.
int defaultPriceForServiceKey(String key) {
  final found = lookupServiceByKey(key);
  return found?.service.priceAvg ?? 0;
}

/// Строит карту цен для списка услуг из каталога.
Map<String, int> buildDefaultServicePrices(Iterable<String> keys) {
  return {
    for (final key in keys) key: defaultPriceForServiceKey(key),
  };
}
