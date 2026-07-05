import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_provider.dart';

final masterFavoritesProvider =
    NotifierProvider<MasterFavoritesNotifier, Set<String>>(MasterFavoritesNotifier.new);

class MasterFavoritesNotifier extends Notifier<Set<String>> {
  bool _loaded = false;

  @override
  Set<String> build() {
    ref.keepAlive();
    Future.microtask(_ensureLoaded);
    return {};
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final json = await ref
          .read(secureStorageProvider)
          .readMasterFavoritesJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return;
      final list = (jsonDecode(json) as List).cast<String>();
      state = list.toSet();
    } catch (_) {}
  }

  Future<void> toggle(String masterKey) async {
    await _ensureLoaded();
    final next = Set<String>.from(state);
    if (!next.add(masterKey)) next.remove(masterKey);
    state = next;
    await ref.read(secureStorageProvider).writeMasterFavoritesJson(
          jsonEncode(next.toList()),
        );
  }

  Future<void> remove(String masterKey) async {
    await _ensureLoaded();
    if (!state.contains(masterKey)) return;
    final next = Set<String>.from(state)..remove(masterKey);
    state = next;
    await ref.read(secureStorageProvider).writeMasterFavoritesJson(
          jsonEncode(next.toList()),
        );
  }

  bool isFavorite(String masterKey) => state.contains(masterKey);
}
