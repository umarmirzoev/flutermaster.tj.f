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
