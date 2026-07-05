import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_provider.dart';
import '../../auth/utils/phone_formatter.dart';
import '../data/master_reviews_seed.dart';
import '../models/master_review.dart';

final masterReviewsProvider =
    NotifierProvider<MasterReviewsNotifier, List<MasterReview>>(MasterReviewsNotifier.new);

class MasterReviewsNotifier extends Notifier<List<MasterReview>> {
  bool _loaded = false;

  @override
  List<MasterReview> build() {
    ref.keepAlive();
    Future.microtask(_ensureLoaded);
    return const [];
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final json = await ref
          .read(secureStorageProvider)
          .readMasterReviewsJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return;
      final list = (jsonDecode(json) as List)
          .map((e) => MasterReview.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> addReview({
    required String masterKey,
    required String authorName,
    required int rating,
    required String body,
    String? clientPhone,
  }) async {
    await _ensureLoaded();
    final review = MasterReview(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      masterKey: masterKey,
      authorName: authorName,
      rating: rating.clamp(1, 5),
      body: body.trim(),
      createdAt: DateTime.now(),
      clientPhone: clientPhone,
    );
    state = [review, ...state];
    await _persist();
  }

  Future<void> _persist() async {
    final json = jsonEncode(state.map((r) => r.toJson()).toList());
    await ref.read(secureStorageProvider).writeMasterReviewsJson(json);
  }
}

List<MasterReview> reviewsForMaster(WidgetRef ref, String masterKey) {
  final user = ref.watch(masterReviewsProvider);
  return [
    ...user.where((r) => r.masterKey == masterKey),
    ...masterReviewsSeed.where((r) => r.masterKey == masterKey),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

MasterReviewStats reviewStatsForMaster(WidgetRef ref, String masterKey, {double fallbackRating = 4.8}) {
  final list = reviewsForMaster(ref, masterKey);
  if (list.isEmpty) {
    return MasterReviewStats(count: 0, averageRating: fallbackRating);
  }
  final sum = list.fold<int>(0, (a, r) => a + r.rating);
  return MasterReviewStats(
    count: list.length,
    averageRating: sum / list.length,
  );
}

final allMasterReviewsProvider = Provider<List<MasterReview>>((ref) {
  final user = ref.watch(masterReviewsProvider);
  final all = [...user, ...masterReviewsSeed];
  all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return all;
});

final masterReviewStatsProvider =
    Provider.family<MasterReviewStats, String>((ref, masterKey) {
  final user = ref.watch(masterReviewsProvider);
  final list = [
    ...user.where((r) => r.masterKey == masterKey),
    ...masterReviewsSeed.where((r) => r.masterKey == masterKey),
  ];
  if (list.isEmpty) {
    return const MasterReviewStats(count: 0, averageRating: 4.8);
  }
  final sum = list.fold<int>(0, (a, r) => a + r.rating);
  return MasterReviewStats(count: list.length, averageRating: sum / list.length);
});

List<MasterReview> reviewsByClientPhone(WidgetRef ref, String? phone) {
  if (phone == null || phone.isEmpty) return const [];
  final digits = localDigitsFromPhone(phone);
  final user = ref.watch(masterReviewsProvider);
  return user.where((r) {
    if (r.clientPhone == null) return false;
    return localDigitsFromPhone(r.clientPhone!) == digits;
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
