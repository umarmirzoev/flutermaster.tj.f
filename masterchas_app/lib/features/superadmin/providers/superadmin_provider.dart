import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/platform_models.dart';
import '../../../core/providers/platform_store_provider.dart';

export '../../../core/models/platform_models.dart';
export '../../../core/providers/platform_store_provider.dart';

final superAdminUiProvider = NotifierProvider<SuperAdminUiNotifier, SuperAdminUiState>(SuperAdminUiNotifier.new);
final superAdminDataProvider = platformStoreProvider;

class SuperAdminUiState {
  const SuperAdminUiState({
    this.sidebarCollapsed = false,
    this.searchQuery = '',
    this.chartPeriod = '30 дней',
    this.activityPeriod = 'Неделя',
    this.language = 'Русский',
  });

  final bool sidebarCollapsed;
  final String searchQuery;
  final String chartPeriod;
  final String activityPeriod;
  final String language;

  SuperAdminUiState copyWith({
    bool? sidebarCollapsed,
    String? searchQuery,
    String? chartPeriod,
    String? activityPeriod,
    String? language,
  }) =>
      SuperAdminUiState(
        sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
        searchQuery: searchQuery ?? this.searchQuery,
        chartPeriod: chartPeriod ?? this.chartPeriod,
        activityPeriod: activityPeriod ?? this.activityPeriod,
        language: language ?? this.language,
      );
}

class SuperAdminUiNotifier extends Notifier<SuperAdminUiState> {
  @override
  SuperAdminUiState build() => const SuperAdminUiState();

  void toggleSidebar() => state = state.copyWith(sidebarCollapsed: !state.sidebarCollapsed);
  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setChartPeriod(String p) => state = state.copyWith(chartPeriod: p);
  void setActivityPeriod(String p) => state = state.copyWith(activityPeriod: p);
}

typedef SuperAdminDataState = PlatformStoreState;
typedef SuperAdminDataNotifier = PlatformStoreNotifier;

List<Map<String, String>> superAdminSearch(String query, {required List<SaProduct> products, required List<SaMaster> masters}) {
  if (query.trim().isEmpty) return const [];
  final q = query.toLowerCase();
  final out = <Map<String, String>>[];
  for (final p in products) {
    if (p.name.toLowerCase().contains(q)) out.add({'type': 'Товар', 'label': p.name, 'route': '/superadmin/shop'});
  }
  for (final m in masters) {
    if (m.name.toLowerCase().contains(q)) out.add({'type': 'Мастер', 'label': m.name, 'route': '/superadmin/masters'});
  }
  return out;
}
