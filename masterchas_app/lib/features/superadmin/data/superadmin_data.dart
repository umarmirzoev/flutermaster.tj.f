import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/models/platform_models.dart';
import '../theme/superadmin_theme.dart';

final superAdminMenu = <SaMenuItem>[
  const SaMenuItem(id: 'home', label: 'Главная', icon: LucideIcons.layout_dashboard, route: '/superadmin/dashboard'),
  const SaMenuItem(id: 'fund', label: 'Фонд', icon: LucideIcons.landmark, route: '/superadmin/fund'),
  const SaMenuItem(id: 'orders', label: 'Заказы', icon: LucideIcons.clipboard_list, route: '/superadmin/orders'),
  const SaMenuItem(id: 'masters', label: 'Мастера', icon: LucideIcons.hard_hat, route: '/superadmin/masters'),
  const SaMenuItem(id: 'clients', label: 'Клиенты', icon: LucideIcons.users, route: '/superadmin/clients'),
  const SaMenuItem(id: 'shop', label: 'Магазин', icon: LucideIcons.store, route: '/superadmin/shop'),
  const SaMenuItem(id: 'products', label: 'Товары', icon: LucideIcons.package, route: '/superadmin/products'),
  const SaMenuItem(id: 'categories', label: 'Категории', icon: LucideIcons.layers, route: '/superadmin/categories'),
  const SaMenuItem(id: 'brands', label: 'Бренды', icon: LucideIcons.tag, route: '/superadmin/brands'),
  const SaMenuItem(id: 'coupons', label: 'Промокоды', icon: LucideIcons.ticket, route: '/superadmin/coupons'),
  const SaMenuItem(id: 'chats', label: 'Чаты', icon: LucideIcons.message_circle, route: '/superadmin/chats'),
  const SaMenuItem(id: 'reviews', label: 'Отзывы', icon: LucideIcons.star, route: '/superadmin/reviews'),
  const SaMenuItem(id: 'finance', label: 'Финансы', icon: LucideIcons.wallet, route: '/superadmin/finance'),
  const SaMenuItem(id: 'analytics', label: 'Аналитика', icon: LucideIcons.chart_bar, route: '/superadmin/analytics'),
  const SaMenuItem(id: 'marketing', label: 'Маркетинг', icon: LucideIcons.megaphone, route: '/superadmin/marketing'),
  const SaMenuItem(id: 'pages', label: 'Страницы', icon: LucideIcons.file_text, route: '/superadmin/pages'),
  const SaMenuItem(id: 'notifications', label: 'Уведомления', icon: LucideIcons.bell, route: '/superadmin/notifications'),
  const SaMenuItem(id: 'support', label: 'Поддержка', icon: LucideIcons.headphones, route: '/superadmin/support'),
  const SaMenuItem(id: 'settings', label: 'Настройки', icon: LucideIcons.settings, route: '/superadmin/settings'),
  const SaMenuItem(id: 'system', label: 'Система', icon: LucideIcons.server, route: '/superadmin/system'),
];

const productCategories = [
  'Электроинструмент',
  'Ручной инструмент',
  'Измерительный',
  'Расходные материалы',
  'Сад и огород',
  'Аудио',
  'Мебель',
];

const productPresetImages = [
  'assets/images/tool_drill.png',
  'assets/images/tool_hammer.png',
  'assets/images/tool_set.png',
  'assets/images/tool_level.png',
  'assets/images/shop_grinder.png',
  'assets/images/shop_saw.png',
  'assets/images/shop_perforator.png',
  'assets/images/shop_washer.png',
  'assets/images/shop_jigsaw.png',
  'assets/images/shop_flashlight.png',
];

const masterPresetAvatars = [
  'assets/images/master_1.png',
  'assets/images/master_2.png',
  'assets/images/master_3.png',
  'assets/images/master_4.png',
  'assets/images/master_5.png',
  'assets/images/master_6.png',
  'assets/images/master_7.png',
  'assets/images/master_8.png',
  'assets/images/master_9.png',
  'assets/images/master_10.png',
  'assets/images/master_11.png',
];

const masterSpecializations = [
  'Сантехник',
  'Электрик',
  'Отделочник',
  'Сварщик',
  'Уборка',
  'Мебельщик',
  'Кондиционеры',
];

String formatSaMoney(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

String saOrderStatusLabel(SaOrderStatus s) => switch (s) {
      SaOrderStatus.newOrder => 'Новый',
      SaOrderStatus.inProgress => 'В работе',
      SaOrderStatus.completed => 'Выполнен',
      SaOrderStatus.cancelled => 'Отменён',
    };

Color saOrderStatusColor(SaOrderStatus s) => switch (s) {
      SaOrderStatus.newOrder => SuperAdminTheme.blue,
      SaOrderStatus.inProgress => SuperAdminTheme.yellow,
      SaOrderStatus.completed => SuperAdminTheme.green,
      SaOrderStatus.cancelled => SuperAdminTheme.red,
    };
