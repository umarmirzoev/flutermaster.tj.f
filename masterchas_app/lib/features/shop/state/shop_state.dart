import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/catalog_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.discount,
    required this.bonus,
    required this.address,
    this.status = 'Новый',
    this.paymentMethod = 'Наличными',
  });

  final String id;
  final DateTime date;
  final Map<int, int> items; // product index -> qty
  final int total;
  final int discount;
  final int bonus;
  final String address;
  final String status;

  /// Способ оплаты: «Наличными» или «Картой •• 1234».
  final String paymentMethod;

  int get count => items.values.fold(0, (a, b) => a + b);
}

class PaymentCard {
  const PaymentCard({
    required this.number,
    required this.holder,
    required this.expiry,
  });

  final String number; // 16 digits, no spaces
  final String holder;
  final String expiry; // MM/YY

  String get last4 => number.length >= 4 ? number.substring(number.length - 4) : number;

  String get brand {
    if (number.startsWith('4')) return 'VISA';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('6')) return 'UnionPay';
    return 'CARD';
  }
}

class ShopAddress {
  const ShopAddress({
    required this.title,
    required this.city,
    required this.street,
    required this.details,
    required this.comment,
  });

  final String title;
  final String city;
  final String street;
  final String details;
  final String comment;

  String get oneLine {
    final parts = [city, street, details].where((e) => e.trim().isNotEmpty);
    return parts.join(', ');
  }
}

// ─── Cart ─────────────────────────────────────────────────────────────────────

final shopCartProvider = NotifierProvider<ShopCartNotifier, Map<int, int>>(ShopCartNotifier.new);

/// Корзина аренды: ключ — индекс в rentalProducts, значение — количество суток.
final rentalCartProvider = NotifierProvider<ShopCartNotifier, Map<int, int>>(ShopCartNotifier.new);

class ShopCartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => {};

  void add(int idx) {
    final m = Map<int, int>.from(state);
    m.update(idx, (v) => v + 1, ifAbsent: () => 1);
    state = m;
  }

  void setQty(int idx, int qty) {
    final m = Map<int, int>.from(state);
    if (qty <= 0) {
      m.remove(idx);
    } else {
      m[idx] = qty;
    }
    state = m;
  }

  void clear() => state = {};

  int get count => state.values.fold(0, (a, b) => a + b);
  int get total => state.entries.fold(0, (a, e) => a + ref.read(shopCatalogProvider)[e.key].price * e.value);
}

// ─── Favorites ──────────────────────────────────────────────────────────────

final shopFavoritesProvider = NotifierProvider<ShopFavoritesNotifier, Set<int>>(ShopFavoritesNotifier.new);

class ShopFavoritesNotifier extends Notifier<Set<int>> {
  bool _loaded = false;

  @override
  Set<int> build() {
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
          .readShopFavoritesJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return;
      final list = (jsonDecode(json) as List).map((e) => (e as num).toInt()).toList();
      state = list.toSet();
    } catch (_) {}
  }

  Future<void> toggle(int idx) async {
    await _ensureLoaded();
    final s = Set<int>.from(state);
    if (!s.add(idx)) s.remove(idx);
    state = s;
    await ref.read(secureStorageProvider).writeShopFavoritesJson(
          jsonEncode(s.toList()),
        );
  }

  Future<void> remove(int idx) async {
    await _ensureLoaded();
    if (!state.contains(idx)) return;
    final s = Set<int>.from(state)..remove(idx);
    state = s;
    await ref.read(secureStorageProvider).writeShopFavoritesJson(
          jsonEncode(s.toList()),
        );
  }
}

final rentalFavoritesProvider =
    NotifierProvider<RentalFavoritesNotifier, Set<int>>(RentalFavoritesNotifier.new);

class RentalFavoritesNotifier extends Notifier<Set<int>> {
  bool _loaded = false;

  @override
  Set<int> build() {
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
          .readRentalFavoritesJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return;
      final list = (jsonDecode(json) as List).map((e) => (e as num).toInt()).toList();
      state = list.toSet();
    } catch (_) {}
  }

  Future<void> toggle(int idx) async {
    await _ensureLoaded();
    final s = Set<int>.from(state);
    if (!s.add(idx)) s.remove(idx);
    state = s;
    await ref.read(secureStorageProvider).writeRentalFavoritesJson(
          jsonEncode(s.toList()),
        );
  }

  Future<void> remove(int idx) async {
    await _ensureLoaded();
    if (!state.contains(idx)) return;
    final s = Set<int>.from(state)..remove(idx);
    state = s;
    await ref.read(secureStorageProvider).writeRentalFavoritesJson(
          jsonEncode(s.toList()),
        );
  }
}

// ─── Orders ───────────────────────────────────────────────────────────────────

final shopOrdersProvider = NotifierProvider<ShopOrdersNotifier, List<ShopOrder>>(ShopOrdersNotifier.new);

class ShopOrdersNotifier extends Notifier<List<ShopOrder>> {
  bool _loaded = false;

  @override
  List<ShopOrder> build() {
    ref.keepAlive();
    Future.microtask(_ensureLoaded);
    return const [];
  }

  Future<void> ensureLoaded() => _ensureLoaded();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final json = await ref
          .read(secureStorageProvider)
          .readShopOrdersJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return;
      final list = jsonDecode(json) as List<dynamic>;
      state = list.map(_orderFromJson).toList();
    } catch (_) {}
  }

  Future<void> add(ShopOrder order) async {
    await _ensureLoaded();
    state = [order, ...state];
    await _persist();
  }

  Future<void> _persist() async {
    await ref.read(secureStorageProvider).writeShopOrdersJson(
          jsonEncode(state.map(_orderToJson).toList()),
        );
  }

  static Map<String, dynamic> _orderToJson(ShopOrder o) => {
        'id': o.id,
        'date': o.date.toIso8601String(),
        'items': o.items.map((k, v) => MapEntry(k.toString(), v)),
        'total': o.total,
        'discount': o.discount,
        'bonus': o.bonus,
        'address': o.address,
        'status': o.status,
        'paymentMethod': o.paymentMethod,
      };

  static ShopOrder _orderFromJson(dynamic raw) {
    final json = raw as Map<String, dynamic>;
    final itemsRaw = json['items'];
    final items = <int, int>{};
    if (itemsRaw is Map) {
      itemsRaw.forEach((k, v) {
        final key = int.tryParse(k.toString());
        final val = (v as num?)?.toInt();
        if (key != null && val != null) items[key] = val;
      });
    }
    return ShopOrder(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      items: items,
      total: (json['total'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      bonus: (json['bonus'] as num?)?.toInt() ?? 0,
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'Новый',
      paymentMethod: json['paymentMethod'] as String? ?? 'Наличными',
    );
  }

  int get totalSpent => state.fold(0, (a, o) => a + o.total);
  int get totalBonus => state.fold(0, (a, o) => a + o.bonus);
  int get totalDiscount => state.fold(0, (a, o) => a + o.discount);
}

// ─── Payment cards ─────────────────────────────────────────────────────────

final shopCardsProvider = NotifierProvider<ShopCardsNotifier, List<PaymentCard>>(ShopCardsNotifier.new);

/// Сохранённые карты. Полный номер карты НЕ храним: на устройстве остаются только
/// первая цифра (для логотипа VISA/Mastercard), последние 4 цифры, имя и срок.
class ShopCardsNotifier extends Notifier<List<PaymentCard>> {
  static const _key = 'shop_cards_masked';

  @override
  List<PaymentCard> build() {
    ref.keepAlive();
    Future.microtask(_load);
    return [];
  }

  Future<void> _load() async {
    try {
      final raw = await ref.read(secureStorageProvider).readSetting(_key).timeout(const Duration(seconds: 2));
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      state = [
        for (final e in list)
          PaymentCard(
            number: (e as Map)['number']?.toString() ?? '',
            holder: e['holder']?.toString() ?? '',
            expiry: e['expiry']?.toString() ?? '',
          ),
      ];
    } catch (_) {}
  }

  static String _mask(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) return digits;
    return '${digits[0]}${'0' * (digits.length - 5)}${digits.substring(digits.length - 4)}';
  }

  Future<void> _save() async {
    try {
      await ref.read(secureStorageProvider).writeSetting(
            _key,
            jsonEncode([
              for (final c in state) {'number': c.number, 'holder': c.holder, 'expiry': c.expiry},
            ]),
          );
    } catch (_) {}
  }

  void add(PaymentCard card) {
    state = [...state, PaymentCard(number: _mask(card.number), holder: card.holder, expiry: card.expiry)];
    _save();
  }

  void removeAt(int i) {
    state = [for (var k = 0; k < state.length; k++) if (k != i) state[k]];
    _save();
  }
}

// ─── Addresses ─────────────────────────────────────────────────────────────

final shopAddressesProvider = NotifierProvider<ShopAddressesNotifier, List<ShopAddress>>(ShopAddressesNotifier.new);

class ShopAddressesNotifier extends Notifier<List<ShopAddress>> {
  bool _loaded = false;

  @override
  List<ShopAddress> build() {
    ref.keepAlive();
    Future.microtask(_ensureLoaded);
    return const [];
  }

  Future<void> ensureLoaded() => _ensureLoaded();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final json = await ref
          .read(secureStorageProvider)
          .readShopAddressesJson()
          .timeout(const Duration(seconds: 2));
      if (json == null || json.isEmpty) return;
      final list = jsonDecode(json) as List<dynamic>;
      state = list.map(_fromJson).toList();
    } catch (_) {}
  }

  Future<void> add(ShopAddress a) async {
    await _ensureLoaded();
    state = [a, ...state.where((x) => x.oneLine != a.oneLine)];
    await _persist();
  }

  Future<void> removeAt(int i) async {
    await _ensureLoaded();
    state = [for (var k = 0; k < state.length; k++) if (k != i) state[k]];
    await _persist();
  }

  String? get lastUsed => state.isNotEmpty ? state.first.oneLine : null;

  Future<void> _persist() async {
    await ref.read(secureStorageProvider).writeShopAddressesJson(
          jsonEncode(state.map(_toJson).toList()),
        );
  }

  static Map<String, dynamic> _toJson(ShopAddress a) => {
        'title': a.title,
        'city': a.city,
        'street': a.street,
        'details': a.details,
        'comment': a.comment,
      };

  static ShopAddress _fromJson(dynamic raw) {
    final json = raw as Map<String, dynamic>;
    return ShopAddress(
      title: json['title'] as String? ?? 'Дом',
      city: json['city'] as String? ?? '',
      street: json['street'] as String? ?? '',
      details: json['details'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
    );
  }
}

// ─── Settings (notifications / security) ─────────────────────────────────────

final shopNotifSettingsProvider =
    NotifierProvider<ShopToggleNotifier, Map<String, bool>>(() => ShopToggleNotifier({
          'push': true,
          'email': false,
          'sms': true,
          'promos': true,
          'orders': true,
        }));

final shopSecuritySettingsProvider =
    NotifierProvider<ShopToggleNotifier, Map<String, bool>>(() => ShopToggleNotifier({
          'biometric': false,
          'pin': true,
          'twofa': false,
        }));

class ShopToggleNotifier extends Notifier<Map<String, bool>> {
  ShopToggleNotifier(this._initial);
  final Map<String, bool> _initial;

  @override
  Map<String, bool> build() => Map<String, bool>.from(_initial);

  void toggle(String key) {
    final m = Map<String, bool>.from(state);
    m[key] = !(m[key] ?? false);
    state = m;
  }
}
