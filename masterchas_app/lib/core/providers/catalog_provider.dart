import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/masters/data/masters_data.dart';
import '../../features/shop/data/shop_data.dart';
import '../../features/superadmin/data/superadmin_data.dart';

String saSpecializationToCategory(String spec) => switch (spec) {
      'Сантехник' => 'Сантехника',
      'Электрик' => 'Электрика',
      'Отделочник' => 'Отделка',
      'Сварщик' => 'Сварочные работы',
      'Уборка' => 'Уборка',
      'Мебельщик' => 'Мебель и двери',
      'Кондиционеры' => 'Кондиционеры',
      _ => 'Сантехника',
    };

int saCategoryIndex(String category) {
  final idx = productCategories.indexOf(category);
  return idx >= 0 ? idx + 1 : 1;
}

class ShopCatalogNotifier extends Notifier<List<ShopProduct>> {
  @override
  List<ShopProduct> build() => List.of(shopProducts);

  void addProduct({
    required String name,
    required String category,
    required int price,
    required String description,
    required String image,
    Uint8List? imageBytes,
  }) {
    state = [
      ...state,
      ShopProduct(
        ru: name,
        en: name,
        image: image,
        price: price,
        oldPrice: 0,
        rating: 5.0,
        ratingsCount: 0,
        orders: 0,
        badge: ProductBadge.isNew,
        categoryIndex: saCategoryIndex(category),
        descRu: description,
        descEn: description,
        imageBytes: imageBytes,
      ),
    ];
  }

  void removeLastAdded() {
    if (state.length > shopProducts.length) {
      state = state.sublist(0, state.length - 1);
    }
  }

  void removeBySaId(String saId) {
    if (saId.startsWith('shop-')) {
      final idx = int.tryParse(saId.replaceFirst('shop-', ''));
      if (idx != null && idx >= 0 && idx < state.length) {
        state = [for (var i = 0; i < state.length; i++) if (i != idx) state[i]];
      }
      return;
    }
    removeLastAdded();
  }
}

class MastersCatalogNotifier extends Notifier<List<MasterItem>> {
  @override
  List<MasterItem> build() => List.of(masters);

  void addMaster({
    required String name,
    required String phone,
    required String specialization,
    required String avatar,
    Uint8List? imageBytes,
  }) {
    final category = saSpecializationToCategory(specialization);
    state = [
      MasterItem(
        fullName: name,
        phone: phone,
        image: avatar,
        bio: 'Специалист: $specialization. Новый мастер на платформе.',
        categories: [category],
        districts: ['Душанбе'],
        experienceYears: 1,
        rating: 5.0,
        reviews: 0,
        priceMin: 50,
        priceMax: 250,
        completedOrders: 0,
        isTop: false,
        isOnline: true,
        imageBytes: imageBytes,
      ),
      ...state,
    ];
  }

  void removeLastAdded() {
    if (state.length > masters.length) {
      state = state.sublist(1);
    }
  }

  void removeBySaId(String saId) {
    if (saId.startsWith('master-')) {
      final idx = int.tryParse(saId.replaceFirst('master-', ''));
      if (idx != null && idx >= 0 && idx < state.length) {
        state = [for (var i = 0; i < state.length; i++) if (i != idx) state[i]];
      }
      return;
    }
    removeLastAdded();
  }
}

final shopCatalogProvider = NotifierProvider<ShopCatalogNotifier, List<ShopProduct>>(ShopCatalogNotifier.new);
final mastersCatalogProvider = NotifierProvider<MastersCatalogNotifier, List<MasterItem>>(MastersCatalogNotifier.new);
