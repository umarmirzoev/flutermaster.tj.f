import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shop_data.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ShopOrder {
  const ShopOrder({
    required this.date,
    required this.items,
    required this.total,
    required this.discount,
    required this.bonus,
  });

  final DateTime date;
  final Map<int, int> items; // product index -> qty
  final int total;
  final int discount;
  final int bonus;

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
  int get total => state.entries.fold(0, (a, e) => a + shopProducts[e.key].price * e.value);
}

// ─── Favorites ──────────────────────────────────────────────────────────────

final shopFavoritesProvider = NotifierProvider<ShopFavoritesNotifier, Set<int>>(ShopFavoritesNotifier.new);

class ShopFavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int idx) {
    final s = Set<int>.from(state);
    if (s.contains(idx)) {
      s.remove(idx);
    } else {
      s.add(idx);
    }
    state = s;
  }

  void remove(int idx) {
    final s = Set<int>.from(state)..remove(idx);
    state = s;
  }
}

// ─── Orders ───────────────────────────────────────────────────────────────────

final shopOrdersProvider = NotifierProvider<ShopOrdersNotifier, List<ShopOrder>>(ShopOrdersNotifier.new);

class ShopOrdersNotifier extends Notifier<List<ShopOrder>> {
  @override
  List<ShopOrder> build() => [];

  void add(ShopOrder order) => state = [order, ...state];

  int get totalSpent => state.fold(0, (a, o) => a + o.total);
  int get totalBonus => state.fold(0, (a, o) => a + o.bonus);
  int get totalDiscount => state.fold(0, (a, o) => a + o.discount);
}

// ─── Payment cards ─────────────────────────────────────────────────────────

final shopCardsProvider = NotifierProvider<ShopCardsNotifier, List<PaymentCard>>(ShopCardsNotifier.new);

class ShopCardsNotifier extends Notifier<List<PaymentCard>> {
  @override
  List<PaymentCard> build() => [];

  void add(PaymentCard card) => state = [...state, card];
  void removeAt(int i) => state = [for (var k = 0; k < state.length; k++) if (k != i) state[k]];
}

// ─── Addresses ─────────────────────────────────────────────────────────────

final shopAddressesProvider = NotifierProvider<ShopAddressesNotifier, List<ShopAddress>>(ShopAddressesNotifier.new);

class ShopAddressesNotifier extends Notifier<List<ShopAddress>> {
  @override
  List<ShopAddress> build() => [];

  void add(ShopAddress a) => state = [...state, a];
  void removeAt(int i) => state = [for (var k = 0; k < state.length; k++) if (k != i) state[k]];
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
