import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/platform_models.dart';
import '../../features/masters/data/masters_data.dart';
import '../../features/shop/data/shop_data.dart';
import '../../features/superadmin/data/superadmin_data.dart';
import 'catalog_provider.dart';

class PlatformStoreState {
  const PlatformStoreState({
    required this.orders,
    required this.clients,
    required this.products,
    required this.masters,
    required this.categories,
    required this.brands,
    required this.coupons,
    required this.chats,
    required this.reviews,
    required this.notifications,
    required this.payouts,
    required this.supportTickets,
    required this.cmsPages,
    required this.marketingLogs,
    required this.settings,
    required this.systemServices,
    required this.charityCases,
    this.nextOrderId = 1000,
    this.nextClientId = 1000,
    this.nextProductId = 1000,
    this.nextMasterId = 1000,
    this.nextCategoryId = 100,
    this.nextBrandId = 100,
    this.nextCouponId = 100,
    this.nextChatId = 100,
    this.nextReviewId = 100,
    this.nextNotificationId = 100,
    this.nextPayoutId = 100,
    this.nextTicketId = 100,
    this.nextPageId = 100,
    this.nextMarketingId = 100,
    this.nextTransactionId = 1000,
    this.nextCharityId = 100,
  });

  final List<SaOrder> orders;
  final List<SaClient> clients;
  final List<SaProduct> products;
  final List<SaMaster> masters;
  final List<SaCategory> categories;
  final List<SaBrand> brands;
  final List<SaCoupon> coupons;
  final List<SaChatThread> chats;
  final List<SaReview> reviews;
  final List<SaNotification> notifications;
  final List<SaPayout> payouts;
  final List<SaSupportTicket> supportTickets;
  final List<SaCmsPage> cmsPages;
  final List<SaMarketingLog> marketingLogs;
  final SaPlatformSettings settings;
  final List<SaSystemService> systemServices;
  final List<SaCharityCase> charityCases;
  final int nextOrderId;
  final int nextClientId;
  final int nextProductId;
  final int nextMasterId;
  final int nextCategoryId;
  final int nextBrandId;
  final int nextCouponId;
  final int nextChatId;
  final int nextReviewId;
  final int nextNotificationId;
  final int nextPayoutId;
  final int nextTicketId;
  final int nextPageId;
  final int nextMarketingId;
  final int nextTransactionId;
  final int nextCharityId;

  int get totalOrderAmount => orders.where((o) => o.status == SaOrderStatus.completed).fold(0, (a, o) => a + o.amount);
  int get monthlyRevenue => totalOrderAmount;
  int get charityFundAmount => (monthlyRevenue * charityFundPercent / 100).round();
  int get charityFundSpent => charityCases.where((c) => c.status == 'Исправлено').fold(0, (a, c) => a + c.estimatedCost);
  int get charityFundReserved => charityCases.where((c) => c.status == 'В работе').fold(0, (a, c) => a + c.estimatedCost);
  int get charityFundAvailable => charityFundAmount - charityFundSpent - charityFundReserved;
  int get unreadChats => chats.fold(0, (a, c) => a + c.unread);
  int get unreadNotifications => notifications.where((n) => !n.read).length;

  PlatformStoreState copyWith({
    List<SaOrder>? orders,
    List<SaClient>? clients,
    List<SaProduct>? products,
    List<SaMaster>? masters,
    List<SaCategory>? categories,
    List<SaBrand>? brands,
    List<SaCoupon>? coupons,
    List<SaChatThread>? chats,
    List<SaReview>? reviews,
    List<SaNotification>? notifications,
    List<SaPayout>? payouts,
    List<SaSupportTicket>? supportTickets,
    List<SaCmsPage>? cmsPages,
    List<SaMarketingLog>? marketingLogs,
    SaPlatformSettings? settings,
    List<SaSystemService>? systemServices,
    List<SaCharityCase>? charityCases,
    int? nextOrderId,
    int? nextClientId,
    int? nextProductId,
    int? nextMasterId,
    int? nextCategoryId,
    int? nextBrandId,
    int? nextCouponId,
    int? nextChatId,
    int? nextReviewId,
    int? nextNotificationId,
    int? nextPayoutId,
    int? nextTicketId,
    int? nextPageId,
    int? nextMarketingId,
    int? nextTransactionId,
    int? nextCharityId,
  }) =>
      PlatformStoreState(
        orders: orders ?? this.orders,
        clients: clients ?? this.clients,
        products: products ?? this.products,
        masters: masters ?? this.masters,
        categories: categories ?? this.categories,
        brands: brands ?? this.brands,
        coupons: coupons ?? this.coupons,
        chats: chats ?? this.chats,
        reviews: reviews ?? this.reviews,
        notifications: notifications ?? this.notifications,
        payouts: payouts ?? this.payouts,
        supportTickets: supportTickets ?? this.supportTickets,
        cmsPages: cmsPages ?? this.cmsPages,
        marketingLogs: marketingLogs ?? this.marketingLogs,
        settings: settings ?? this.settings,
        systemServices: systemServices ?? this.systemServices,
        charityCases: charityCases ?? this.charityCases,
        nextOrderId: nextOrderId ?? this.nextOrderId,
        nextClientId: nextClientId ?? this.nextClientId,
        nextProductId: nextProductId ?? this.nextProductId,
        nextMasterId: nextMasterId ?? this.nextMasterId,
        nextCategoryId: nextCategoryId ?? this.nextCategoryId,
        nextBrandId: nextBrandId ?? this.nextBrandId,
        nextCouponId: nextCouponId ?? this.nextCouponId,
        nextChatId: nextChatId ?? this.nextChatId,
        nextReviewId: nextReviewId ?? this.nextReviewId,
        nextNotificationId: nextNotificationId ?? this.nextNotificationId,
        nextPayoutId: nextPayoutId ?? this.nextPayoutId,
        nextTicketId: nextTicketId ?? this.nextTicketId,
        nextPageId: nextPageId ?? this.nextPageId,
        nextMarketingId: nextMarketingId ?? this.nextMarketingId,
        nextTransactionId: nextTransactionId ?? this.nextTransactionId,
        nextCharityId: nextCharityId ?? this.nextCharityId,
      );
}

List<SaProduct> _buildInitialProducts() {
  return [
    for (var i = 0; i < shopProducts.length; i++)
      SaProduct(
        id: 'shop-$i',
        name: shopProducts[i].ru,
        category: productCategories[shopProducts[i].categoryIndex.clamp(1, productCategories.length) - 1],
        price: shopProducts[i].price,
        image: shopProducts[i].image,
        sold: shopProducts[i].orders,
        inStock: true,
        description: shopProducts[i].descRu,
      ),
  ];
}

List<SaMaster> _buildInitialMasters() {
  return [
    for (var i = 0; i < masters.length; i++)
      SaMaster(
        id: 'master-$i',
        name: masters[i].fullName,
        avatar: masters[i].image,
        rating: masters[i].rating,
        orders: masters[i].completedOrders,
        phone: masters[i].phone,
        specialization: masters[i].categories.first,
      ),
  ];
}

List<SaCategory> _buildInitialCategories() => [
      for (var i = 0; i < productCategories.length; i++)
        SaCategory(id: 'cat-$i', name: productCategories[i], productCount: 0),
    ];

List<SaBrand> _buildInitialBrands() => const [
      SaBrand(id: 'br-1', name: 'BERALI', productCount: 0),
      SaBrand(id: 'br-2', name: 'Makita', productCount: 0),
      SaBrand(id: 'br-3', name: 'DeWALT', productCount: 0),
      SaBrand(id: 'br-4', name: 'Bosch', productCount: 0),
    ];

class PlatformStoreNotifier extends Notifier<PlatformStoreState> {
  @override
  PlatformStoreState build() {
    final products = _buildInitialProducts();
    final categories = _buildInitialCategories();
    for (var i = 0; i < categories.length; i++) {
      final name = categories[i].name;
      final count = products.where((p) => p.category == name).length;
      categories[i] = SaCategory(id: categories[i].id, name: name, productCount: count);
    }
    return PlatformStoreState(
      orders: const [],
      clients: const [],
      products: products,
      masters: _buildInitialMasters(),
      categories: categories,
      brands: _buildInitialBrands(),
      coupons: const [],
      chats: const [],
      reviews: const [],
      notifications: const [],
      payouts: const [],
      supportTickets: const [],
      cmsPages: const [
        SaCmsPage(id: 'pg-1', title: 'Главная', status: 'Опубликована'),
        SaCmsPage(id: 'pg-2', title: 'О нас', status: 'Опубликована'),
        SaCmsPage(id: 'pg-3', title: 'Контакты', status: 'Черновик'),
      ],
      marketingLogs: const [],
      settings: const SaPlatformSettings(),
      systemServices: const [
        SaSystemService(name: 'Сервер', status: 'Работает', detail: 'OK'),
        SaSystemService(name: 'База данных', status: 'Работает', detail: 'OK'),
        SaSystemService(name: 'Redis', status: 'Работает', detail: 'OK'),
        SaSystemService(name: 'Платежи', status: 'Работает', detail: 'OK'),
        SaSystemService(name: 'Push', status: 'Работает', detail: 'OK'),
        SaSystemService(name: 'Хранилище', status: '78%', detail: '78% занято'),
      ],
      charityCases: const [],
    );
  }

  void _syncCategoryCounts() {
    final products = state.products;
    state = state.copyWith(
      categories: [
        for (final c in state.categories)
          SaCategory(
            id: c.id,
            name: c.name,
            productCount: products.where((p) => p.category == c.name).length,
            active: c.active,
          ),
      ],
    );
  }

  void _syncBrandCounts() {
    final products = state.products;
    state = state.copyWith(
      brands: [
        for (final b in state.brands)
          SaBrand(
            id: b.id,
            name: b.name,
            productCount: products.where((p) => p.brand == b.name).length,
            active: b.active,
          ),
      ],
    );
  }

  String _nowDate() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}.${n.month.toString().padLeft(2, '0')}.${n.year}';
  }

  String _nowTime() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  // ─── Orders ───────────────────────────────────────────────────────────────

  void addOrder({required String client, required String master, required String service, required int amount}) {
    final id = '#${state.nextOrderId}';
    state = state.copyWith(
      nextOrderId: state.nextOrderId + 1,
      orders: [
        SaOrder(id: id, client: client, master: master, service: service, date: _nowDate(), status: SaOrderStatus.newOrder, amount: amount),
        ...state.orders,
      ],
    );
    _pushNotification('Новый заказ $id', LucideIcons.clipboard_list);
  }

  void updateOrderStatus(String id, SaOrderStatus status) {
    state = state.copyWith(
      orders: [for (final o in state.orders) if (o.id == id) SaOrder(id: o.id, client: o.client, master: o.master, service: o.service, date: o.date, status: status, amount: o.amount) else o],
    );
    if (status == SaOrderStatus.completed) {
      final order = state.orders.firstWhere((o) => o.id == id);
      addPayout(master: order.master, amount: (order.amount * 0.85).round(), method: 'Humo', paid: false);
    }
  }

  void removeOrder(String id) => state = state.copyWith(orders: state.orders.where((o) => o.id != id).toList());

  /// Заменяет заказы, клиентов и мастеров данными с API (админ-панель).
  void syncApiCatalog({
    required List<SaOrder> orders,
    required List<SaClient> clients,
    required List<SaMaster> masters,
  }) {
    state = state.copyWith(orders: orders, clients: clients, masters: masters);
  }

  // ─── Clients ──────────────────────────────────────────────────────────────

  void addClient({required String name, required String phone, String avatar = 'assets/images/master_1.png'}) {
    final id = 'cl-${state.nextClientId}';
    state = state.copyWith(
      nextClientId: state.nextClientId + 1,
      clients: [
        SaClient(id: id, name: name, phone: phone, avatar: avatar, date: _nowDate(), isNew: true),
        ...state.clients,
      ],
    );
  }

  void updateClient(String id, {String? name, String? phone, bool? isVip}) {
    state = state.copyWith(
      clients: [
        for (final c in state.clients)
          if (c.id == id)
            SaClient(id: c.id, name: name ?? c.name, phone: phone ?? c.phone, avatar: c.avatar, date: c.date, isNew: c.isNew, orders: c.orders, spent: c.spent, isVip: isVip ?? c.isVip)
          else
            c,
      ],
    );
  }

  void removeClient(String id) => state = state.copyWith(clients: state.clients.where((c) => c.id != id).toList());

  // ─── Products ─────────────────────────────────────────────────────────────

  void addProduct({
    required String name,
    required String category,
    required int price,
    required String description,
    required String image,
    Uint8List? imageBytes,
    String brand = '',
  }) {
    final id = 'p-${state.nextProductId}';
    state = state.copyWith(
      nextProductId: state.nextProductId + 1,
      products: [
        SaProduct(id: id, name: name, category: category, price: price, image: image, sold: 0, inStock: true, description: description, imageBytes: imageBytes, brand: brand),
        ...state.products,
      ],
    );
    ref.read(shopCatalogProvider.notifier).addProduct(name: name, category: category, price: price, description: description, image: image, imageBytes: imageBytes);
    _syncCategoryCounts();
    _syncBrandCounts();
  }

  void updateProduct(String id, {String? name, String? category, int? price, String? description, bool? inStock, String? brand}) {
    state = state.copyWith(
      products: [
        for (final p in state.products)
          if (p.id == id)
            SaProduct(
              id: p.id,
              name: name ?? p.name,
              category: category ?? p.category,
              price: price ?? p.price,
              image: p.image,
              sold: p.sold,
              inStock: inStock ?? p.inStock,
              description: description ?? p.description,
              imageBytes: p.imageBytes,
              brand: brand ?? p.brand,
            )
          else
            p,
      ],
    );
    _syncCategoryCounts();
    _syncBrandCounts();
  }

  void toggleProductStock(String id) => updateProduct(id, inStock: !state.products.firstWhere((p) => p.id == id).inStock);

  void removeProduct(String id) {
    state = state.copyWith(products: state.products.where((p) => p.id != id).toList());
    ref.read(shopCatalogProvider.notifier).removeBySaId(id);
    _syncCategoryCounts();
    _syncBrandCounts();
  }

  // ─── Masters ──────────────────────────────────────────────────────────────

  void addMaster({required String name, required String phone, required String specialization, required String avatar, Uint8List? imageBytes}) {
    final id = 'm-${state.nextMasterId}';
    state = state.copyWith(
      nextMasterId: state.nextMasterId + 1,
      masters: [
        SaMaster(id: id, name: name, avatar: avatar, rating: 5.0, orders: 0, phone: phone, specialization: specialization, imageBytes: imageBytes),
        ...state.masters,
      ],
    );
    ref.read(mastersCatalogProvider.notifier).addMaster(name: name, phone: phone, specialization: specialization, avatar: avatar, imageBytes: imageBytes);
  }

  void updateMaster(String id, {String? name, String? phone, String? specialization}) {
    state = state.copyWith(
      masters: [
        for (final m in state.masters)
          if (m.id == id)
            SaMaster(id: m.id, name: name ?? m.name, avatar: m.avatar, rating: m.rating, orders: m.orders, phone: phone ?? m.phone, specialization: specialization ?? m.specialization, imageBytes: m.imageBytes)
          else
            m,
      ],
    );
  }

  void removeMaster(String id) {
    state = state.copyWith(masters: state.masters.where((m) => m.id != id).toList());
    ref.read(mastersCatalogProvider.notifier).removeBySaId(id);
  }

  // ─── Categories / Brands / Coupons ────────────────────────────────────────

  void addCategory(String name) {
    final id = 'cat-${state.nextCategoryId}';
    state = state.copyWith(nextCategoryId: state.nextCategoryId + 1, categories: [...state.categories, SaCategory(id: id, name: name, productCount: 0)]);
  }

  void updateCategory(String id, {String? name, bool? active}) {
    state = state.copyWith(
      categories: [for (final c in state.categories) if (c.id == id) SaCategory(id: c.id, name: name ?? c.name, productCount: c.productCount, active: active ?? c.active) else c],
    );
  }

  void removeCategory(String id) => state = state.copyWith(categories: state.categories.where((c) => c.id != id).toList());

  void addBrand(String name) {
    final id = 'br-${state.nextBrandId}';
    state = state.copyWith(nextBrandId: state.nextBrandId + 1, brands: [...state.brands, SaBrand(id: id, name: name, productCount: 0)]);
  }

  void updateBrand(String id, {String? name, bool? active}) {
    state = state.copyWith(
      brands: [for (final b in state.brands) if (b.id == id) SaBrand(id: b.id, name: name ?? b.name, productCount: b.productCount, active: active ?? b.active) else b],
    );
  }

  void removeBrand(String id) => state = state.copyWith(brands: state.brands.where((b) => b.id != id).toList());

  void addCoupon({required String code, required String description, required int discountPercent}) {
    final id = 'cp-${state.nextCouponId}';
    state = state.copyWith(
      nextCouponId: state.nextCouponId + 1,
      coupons: [...state.coupons, SaCoupon(id: id, code: code, description: description, discountPercent: discountPercent)],
    );
  }

  void updateCoupon(String id, {bool? active}) {
    state = state.copyWith(
      coupons: [for (final c in state.coupons) if (c.id == id) SaCoupon(id: c.id, code: c.code, description: c.description, discountPercent: c.discountPercent, active: active ?? c.active, uses: c.uses) else c],
    );
  }

  void removeCoupon(String id) => state = state.copyWith(coupons: state.coupons.where((c) => c.id != id).toList());

  // ─── Chats ────────────────────────────────────────────────────────────────

  void addChat({required String name}) {
    final id = 'ch-${state.nextChatId}';
    state = state.copyWith(
      nextChatId: state.nextChatId + 1,
      chats: [
        SaChatThread(id: id, name: name, avatar: name.isNotEmpty ? name[0] : '?', lastMessage: 'Новый чат', time: _nowTime(), unread: 0, messages: const []),
        ...state.chats,
      ],
    );
  }

  void sendChatMessage(String chatId, String text, {bool isAdmin = true}) {
    final time = _nowTime();
    state = state.copyWith(
      chats: [
        for (final c in state.chats)
          if (c.id == chatId)
            SaChatThread(
              id: c.id,
              name: c.name,
              avatar: c.avatar,
              lastMessage: text,
              time: time,
              unread: isAdmin ? 0 : c.unread + 1,
              messages: [...c.messages, SaChatMessage(text: text, isAdmin: isAdmin, time: time)],
            )
          else
            c,
      ],
    );
  }

  void markChatRead(String chatId) {
    state = state.copyWith(
      chats: [for (final c in state.chats) if (c.id == chatId) SaChatThread(id: c.id, name: c.name, avatar: c.avatar, lastMessage: c.lastMessage, time: c.time, unread: 0, messages: c.messages) else c],
    );
  }

  void removeChat(String id) => state = state.copyWith(chats: state.chats.where((c) => c.id != id).toList());

  // ─── Reviews ──────────────────────────────────────────────────────────────

  void addReview({required String author, required String master, required int rating, required String text}) {
    final id = 'rv-${state.nextReviewId}';
    state = state.copyWith(
      nextReviewId: state.nextReviewId + 1,
      reviews: [
        SaReview(id: id, author: author, avatar: author.isNotEmpty ? author[0] : '?', text: text, rating: rating, master: master, date: _nowDate(), flagged: rating < 3),
        ...state.reviews,
      ],
    );
  }

  void toggleReviewHidden(String id) {
    state = state.copyWith(
      reviews: [for (final r in state.reviews) if (r.id == id) SaReview(id: r.id, author: r.author, avatar: r.avatar, text: r.text, rating: r.rating, master: r.master, date: r.date, hidden: !r.hidden, flagged: r.flagged) else r],
    );
  }

  void removeReview(String id) => state = state.copyWith(reviews: state.reviews.where((r) => r.id != id).toList());

  // ─── Finance ──────────────────────────────────────────────────────────────

  void addPayout({required String master, required int amount, required String method, required bool paid}) {
    final id = 'py-${state.nextPayoutId}';
    state = state.copyWith(
      nextPayoutId: state.nextPayoutId + 1,
      payouts: [SaPayout(id: id, master: master, amount: amount, method: method, date: _nowDate(), paid: paid), ...state.payouts],
    );
  }

  void togglePayoutPaid(String id) {
    state = state.copyWith(
      payouts: [for (final p in state.payouts) if (p.id == id) SaPayout(id: p.id, master: p.master, amount: p.amount, method: p.method, date: p.date, paid: !p.paid) else p],
    );
  }

  void removePayout(String id) => state = state.copyWith(payouts: state.payouts.where((p) => p.id != id).toList());

  // ─── Support / CMS / Marketing / Notifications / Settings ───────────────

  void addSupportTicket({required String title, required String description}) {
    final id = 'T-${state.nextTicketId}';
    state = state.copyWith(
      nextTicketId: state.nextTicketId + 1,
      supportTickets: [SaSupportTicket(id: id, title: title, status: 'Открыт', date: _nowDate(), description: description), ...state.supportTickets],
    );
  }

  void updateTicketStatus(String id, String status) {
    state = state.copyWith(
      supportTickets: [for (final t in state.supportTickets) if (t.id == id) SaSupportTicket(id: t.id, title: t.title, status: status, date: t.date, description: t.description) else t],
    );
  }

  void removeTicket(String id) => state = state.copyWith(supportTickets: state.supportTickets.where((t) => t.id != id).toList());

  void addCmsPage(String title) {
    final id = 'pg-${state.nextPageId}';
    state = state.copyWith(nextPageId: state.nextPageId + 1, cmsPages: [...state.cmsPages, SaCmsPage(id: id, title: title, status: 'Черновик')]);
  }

  void updateCmsPage(String id, {String? title, String? status}) {
    state = state.copyWith(
      cmsPages: [for (final p in state.cmsPages) if (p.id == id) SaCmsPage(id: p.id, title: title ?? p.title, status: status ?? p.status) else p],
    );
  }

  void removeCmsPage(String id) => state = state.copyWith(cmsPages: state.cmsPages.where((p) => p.id != id).toList());

  void sendMarketing(String text, int recipients) {
    final id = 'mk-${state.nextMarketingId}';
    state = state.copyWith(
      nextMarketingId: state.nextMarketingId + 1,
      marketingLogs: [SaMarketingLog(id: id, text: text, sentAt: '${_nowDate()} ${_nowTime()}', recipients: recipients), ...state.marketingLogs],
    );
  }

  void _pushNotification(String title, IconData icon) {
    final id = 'nt-${state.nextNotificationId}';
    state = state.copyWith(
      nextNotificationId: state.nextNotificationId + 1,
      notifications: [
        SaNotification(id: id, title: title, time: 'только что', icon: icon, color: const Color(0xFF10B981)),
        ...state.notifications,
      ],
    );
  }

  void markNotificationRead(String id) {
    state = state.copyWith(
      notifications: [for (final n in state.notifications) if (n.id == id) SaNotification(id: n.id, title: n.title, time: n.time, icon: n.icon, color: n.color, read: true) else n],
    );
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      notifications: [for (final n in state.notifications) SaNotification(id: n.id, title: n.title, time: n.time, icon: n.icon, color: n.color, read: true)],
    );
  }

  void updateSettings(SaPlatformSettings settings) => state = state.copyWith(settings: settings);

  void updateSystemService(String name, String status, String detail) {
    state = state.copyWith(
      systemServices: [for (final s in state.systemServices) if (s.name == name) SaSystemService(name: name, status: status, detail: detail) else s],
    );
  }

  void addCharityCase({
    required String organizationType,
    required String organizationName,
    required String problem,
    required int estimatedCost,
  }) {
    final id = 'chf-${state.nextCharityId}';
    state = state.copyWith(
      nextCharityId: state.nextCharityId + 1,
      charityCases: [
        SaCharityCase(
          id: id,
          organizationType: organizationType,
          organizationName: organizationName,
          problem: problem,
          estimatedCost: estimatedCost,
          date: _nowDate(),
        ),
        ...state.charityCases,
      ],
    );
  }

  void updateCharityCaseStatus(String id, String status) {
    state = state.copyWith(
      charityCases: [
        for (final c in state.charityCases)
          if (c.id == id)
            SaCharityCase(
              id: c.id,
              organizationType: c.organizationType,
              organizationName: c.organizationName,
              problem: c.problem,
              estimatedCost: c.estimatedCost,
              date: c.date,
              status: status,
            )
          else
            c,
      ],
    );
  }

  void removeCharityCase(String id) {
    state = state.copyWith(charityCases: state.charityCases.where((c) => c.id != id).toList());
  }
}

final platformStoreProvider = NotifierProvider<PlatformStoreNotifier, PlatformStoreState>(PlatformStoreNotifier.new);

List<SaChartPoint> computeOrdersChart(List<SaOrder> orders) {
  if (orders.isEmpty) return const [SaChartPoint(label: 'Нет', value: 1)];
  final buckets = <String, double>{};
  for (final o in orders) {
    buckets[o.date] = (buckets[o.date] ?? 0) + 1;
  }
  return buckets.entries.take(7).map((e) => SaChartPoint(label: e.key.length > 5 ? e.key.substring(0, 5) : e.key, value: e.value)).toList();
}

List<SaChartPoint> computeIncomeChart(List<SaPayout> payouts) {
  if (payouts.isEmpty) return const [SaChartPoint(label: 'Нет', value: 1)];
  return payouts.take(6).map((p) => SaChartPoint(label: p.master.split(' ').first, value: p.amount.toDouble())).toList();
}

List<Map<String, String>> platformSearch(PlatformStoreState state, String query) {
  if (query.trim().isEmpty) return const [];
  final q = query.toLowerCase();
  final out = <Map<String, String>>[];
  for (final o in state.orders) {
    if (o.id.toLowerCase().contains(q) || o.client.toLowerCase().contains(q)) {
      out.add({'type': 'Заказ', 'label': '${o.id} — ${o.client}', 'route': '/superadmin/orders'});
    }
  }
  for (final p in state.products) {
    if (p.name.toLowerCase().contains(q)) out.add({'type': 'Товар', 'label': p.name, 'route': '/superadmin/shop'});
  }
  for (final m in state.masters) {
    if (m.name.toLowerCase().contains(q)) out.add({'type': 'Мастер', 'label': m.name, 'route': '/superadmin/masters'});
  }
  return out;
}
