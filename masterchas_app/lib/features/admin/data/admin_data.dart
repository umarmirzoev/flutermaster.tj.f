import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/models/platform_models.dart';
import '../models/admin_models.dart';

final adminMenuItems = <AdminMenuItem>[
  const AdminMenuItem(
    id: 'dashboard',
    label: 'Дашборд',
    icon: LucideIcons.layout_dashboard,
    route: '/admin/dashboard',
  ),
  AdminMenuItem(
    id: 'orders',
    label: 'Заказы',
    icon: LucideIcons.clipboard_list,
    route: '/admin/orders',
    children: [
      const AdminMenuChild(label: 'Все заказы', route: '/admin/orders'),
      const AdminMenuChild(label: 'Новые', route: '/admin/orders/new'),
      const AdminMenuChild(label: 'В работе', route: '/admin/orders/in-progress'),
      const AdminMenuChild(label: 'Выполнено', route: '/admin/orders/completed'),
      const AdminMenuChild(label: 'Отменено', route: '/admin/orders/cancelled'),
    ],
  ),
  AdminMenuItem(
    id: 'masters',
    label: 'Мастера',
    icon: LucideIcons.hard_hat,
    route: '/admin/masters',
    children: [
      const AdminMenuChild(label: 'Все мастера', route: '/admin/masters'),
      const AdminMenuChild(label: 'На модерации', route: '/admin/masters/pending'),
      const AdminMenuChild(label: 'Топ мастера', route: '/admin/masters/top'),
      const AdminMenuChild(label: 'Заблокированные', route: '/admin/masters/blocked'),
    ],
  ),
  AdminMenuItem(
    id: 'clients',
    label: 'Клиенты',
    icon: LucideIcons.users,
    route: '/admin/clients',
    children: [
      const AdminMenuChild(label: 'Все клиенты', route: '/admin/clients'),
      const AdminMenuChild(label: 'VIP клиенты', route: '/admin/clients/vip'),
      const AdminMenuChild(label: 'Новые', route: '/admin/clients/new'),
    ],
  ),
  const AdminMenuItem(
    id: 'chats',
    label: 'Чаты',
    icon: LucideIcons.message_circle,
    route: '/admin/chats',
    badge: 4,
  ),
  AdminMenuItem(
    id: 'reviews',
    label: 'Отзывы',
    icon: LucideIcons.star,
    route: '/admin/reviews',
    children: [
      const AdminMenuChild(label: 'Все отзывы', route: '/admin/reviews'),
      const AdminMenuChild(label: 'На модерации', route: '/admin/reviews/pending'),
      const AdminMenuChild(label: 'Жалобы', route: '/admin/reviews/flagged'),
    ],
  ),
  AdminMenuItem(
    id: 'finance',
    label: 'Финансы',
    icon: LucideIcons.wallet,
    route: '/admin/finance',
    children: [
      const AdminMenuChild(label: 'Транзакции', route: '/admin/finance'),
      const AdminMenuChild(label: 'Выплаты', route: '/admin/finance/payouts'),
      const AdminMenuChild(label: 'Комиссия', route: '/admin/finance/commission'),
    ],
  ),
  AdminMenuItem(
    id: 'analytics',
    label: 'Аналитика',
    icon: LucideIcons.chart_bar,
    route: '/admin/analytics',
    children: [
      const AdminMenuChild(label: 'Обзор', route: '/admin/analytics'),
      const AdminMenuChild(label: 'По услугам', route: '/admin/analytics/services'),
      const AdminMenuChild(label: 'По районам', route: '/admin/analytics/districts'),
    ],
  ),
  AdminMenuItem(
    id: 'settings',
    label: 'Настройки',
    icon: LucideIcons.settings,
    route: '/admin/settings',
    children: [
      const AdminMenuChild(label: 'Общие', route: '/admin/settings'),
      const AdminMenuChild(label: 'Категории', route: '/admin/settings/categories'),
      const AdminMenuChild(label: 'Промокоды', route: '/admin/settings/promos'),
      const AdminMenuChild(label: 'Уведомления', route: '/admin/settings/notifications'),
    ],
  ),
  const AdminMenuItem(
    id: 'support',
    label: 'Поддержка',
    icon: LucideIcons.headphones,
    route: '/admin/support',
  ),
];

final initialAdminOrders = <AdminOrder>[
  const AdminOrder(id: '#MC-1042', fullId: '#MC-1042', client: 'Али Рахимов', master: 'Гулмахмад Д.', service: 'Сантехника', status: AdminOrderStatus.inProgress, date: '28.06.2026', amount: 150),
  const AdminOrder(id: '#MC-1041', fullId: '#MC-1041', client: 'Мадина К.', master: 'Фаррух С.', service: 'Электрика', status: AdminOrderStatus.newOrder, date: '28.06.2026', amount: 220),
  const AdminOrder(id: '#MC-1040', fullId: '#MC-1040', client: 'Бахтиёр Н.', master: 'Рустам А.', service: 'Отделка', status: AdminOrderStatus.completed, date: '27.06.2026', amount: 890),
  const AdminOrder(id: '#MC-1039', fullId: '#MC-1039', client: 'Зухра М.', master: 'Гулмахмад Д.', service: 'Сантехника', status: AdminOrderStatus.completed, date: '27.06.2026', amount: 180),
  const AdminOrder(id: '#MC-1038', fullId: '#MC-1038', client: 'Саид А.', master: '—', service: 'Мебель', status: AdminOrderStatus.cancelled, date: '26.06.2026', amount: 0),
  const AdminOrder(id: '#MC-1037', fullId: '#MC-1037', client: 'Нигора Т.', master: 'Фаррух С.', service: 'Электрика', status: AdminOrderStatus.inProgress, date: '26.06.2026', amount: 310),
  const AdminOrder(id: '#MC-1036', fullId: '#MC-1036', client: 'Джамшед Х.', master: 'Рустам А.', service: 'Уборка', status: AdminOrderStatus.newOrder, date: '25.06.2026', amount: 120),
];

final initialAdminMasters = <AdminMaster>[
  const AdminMaster(id: 'm1', name: 'Гулмахмад Давлатов', avatar: 'assets/images/master_1.png', specialization: 'Сантехник', orders: 124, rating: 4.9, income: 45200, status: AdminMasterStatus.top, phone: '+992 90 123 4567'),
  const AdminMaster(id: 'm2', name: 'Фаррух Саидов', avatar: 'assets/images/master_2.png', specialization: 'Электрик', orders: 98, rating: 4.8, income: 38100, status: AdminMasterStatus.active, phone: '+992 91 234 5678'),
  const AdminMaster(id: 'm3', name: 'Рустам Алиев', avatar: 'assets/images/master_3.png', specialization: 'Отделочник', orders: 76, rating: 4.7, income: 52800, status: AdminMasterStatus.active, phone: '+992 92 345 6789'),
  const AdminMaster(id: 'm4', name: 'Шахло Мирзоева', avatar: 'assets/images/master_4.png', specialization: 'Уборка', orders: 45, rating: 4.6, income: 18900, status: AdminMasterStatus.pending, phone: '+992 93 456 7890'),
  const AdminMaster(id: 'm5', name: 'Ибрагим К.', avatar: 'assets/images/master_5.png', specialization: 'Мебельщик', orders: 12, rating: 3.2, income: 4200, status: AdminMasterStatus.blocked, phone: '+992 94 567 8901'),
];

final initialAdminClients = <AdminClient>[
  const AdminClient(id: 'c1', name: 'Али Рахимов', phone: '+992 97 111 2233', orders: 8, spent: 2450, joined: '12.01.2025', isVip: true),
  const AdminClient(id: 'c2', name: 'Мадина Курбонова', phone: '+992 98 222 3344', orders: 5, spent: 1320, joined: '03.03.2025', isVip: false),
  const AdminClient(id: 'c3', name: 'Бахтиёр Назаров', phone: '+992 90 333 4455', orders: 12, spent: 5680, joined: '20.11.2024', isVip: true),
  const AdminClient(id: 'c4', name: 'Зухра Мирзоева', phone: '+992 91 444 5566', orders: 2, spent: 380, joined: '15.06.2026', isVip: false),
  const AdminClient(id: 'c5', name: 'Саид Алиев', phone: '+992 92 555 6677', orders: 1, spent: 0, joined: '28.06.2026', isVip: false),
];

final initialAdminChats = <AdminChat>[
  const AdminChat(id: 'ch1', name: 'Али', avatar: 'А', lastMessage: 'Когда приедет мастер?', time: '14:30', unread: 2),
  const AdminChat(id: 'ch2', name: 'Мадина', avatar: 'М', lastMessage: 'Спасибо за помощь!', time: '13:15', unread: 0),
  const AdminChat(id: 'ch3', name: 'Бахтиёр', avatar: 'Б', lastMessage: 'Можно перенести заказ?', time: '12:40', unread: 1),
  const AdminChat(id: 'ch4', name: 'Зухра', avatar: 'З', lastMessage: 'Сколько стоит установка?', time: '11:20', unread: 3),
];

final initialAdminReviews = <AdminReview>[
  const AdminReview(id: 'r1', author: 'Али Р.', master: 'Гулмахмад Д.', rating: 5, text: 'Отличная работа, всё быстро и качественно!', date: '27.06.2026', flagged: false),
  const AdminReview(id: 'r2', author: 'Мадина К.', master: 'Фаррух С.', rating: 4, text: 'Хороший мастер, но опоздал на 20 минут.', date: '26.06.2026', flagged: false),
  const AdminReview(id: 'r3', author: 'Аноним', master: 'Ибрагим К.', rating: 1, text: 'Не рекомендую, плохое качество.', date: '25.06.2026', flagged: true),
];

final initialAdminTransactions = <AdminTransaction>[
  const AdminTransaction(id: 'T-8821', type: 'Комиссия', amount: 450, party: 'Заказ #MC-1040', date: '27.06.2026', status: 'Завершено'),
  const AdminTransaction(id: 'T-8820', type: 'Выплата', amount: 12500, party: 'Гулмахмад Д.', date: '27.06.2026', status: 'Обработка'),
  const AdminTransaction(id: 'T-8819', type: 'Комиссия', amount: 220, party: 'Заказ #MC-1039', date: '27.06.2026', status: 'Завершено'),
  const AdminTransaction(id: 'T-8818', type: 'Возврат', amount: -150, party: 'Саид А.', date: '26.06.2026', status: 'Завершено'),
];

final ordersByDayChart = <AdminChartPoint>[
  const AdminChartPoint(label: '01', value: 4),
  const AdminChartPoint(label: '05', value: 7),
  const AdminChartPoint(label: '10', value: 5),
  const AdminChartPoint(label: '15', value: 9),
  const AdminChartPoint(label: '20', value: 6),
  const AdminChartPoint(label: '25', value: 11),
  const AdminChartPoint(label: '30', value: 8),
];

final incomeByMonthChart = <AdminChartPoint>[
  const AdminChartPoint(label: 'Дек', value: 180),
  const AdminChartPoint(label: 'Янв', value: 210),
  const AdminChartPoint(label: 'Фев', value: 195),
  const AdminChartPoint(label: 'Мар', value: 240),
  const AdminChartPoint(label: 'Апр', value: 280),
  const AdminChartPoint(label: 'Май', value: 325),
];

final userActivityChart = <AdminChartPoint>[
  const AdminChartPoint(label: '01', value: 120),
  const AdminChartPoint(label: '08', value: 145),
  const AdminChartPoint(label: '15', value: 132),
  const AdminChartPoint(label: '22', value: 168),
  const AdminChartPoint(label: '30', value: 155),
];

final masterActivityChart = <AdminChartPoint>[
  const AdminChartPoint(label: '01', value: 45),
  const AdminChartPoint(label: '08', value: 52),
  const AdminChartPoint(label: '15', value: 48),
  const AdminChartPoint(label: '22', value: 61),
  const AdminChartPoint(label: '30', value: 55),
];

String workflowStatusLabel(int code) => switch (code) {
      1 => 'Создан',
      2 => 'Ожидает мастера',
      3 => 'Назначен',
      4 => 'Мастер принял',
      5 => 'В работе',
      6 => 'Завершён',
      7 => 'Отменён',
      8 => 'Спор',
      _ => 'Неизвестно',
    };

String orderStatusLabel(AdminOrderStatus s) => switch (s) {
      AdminOrderStatus.newOrder => 'Новый',
      AdminOrderStatus.inProgress => 'В работе',
      AdminOrderStatus.completed => 'Выполнено',
      AdminOrderStatus.cancelled => 'Отменено',
    };

String masterStatusLabel(AdminMasterStatus s) => switch (s) {
      AdminMasterStatus.active => 'Активен',
      AdminMasterStatus.pending => 'На модерации',
      AdminMasterStatus.blocked => 'Заблокирован',
      AdminMasterStatus.top => 'Топ мастер',
    };

/// Резервные данные админки, если API временно недоступен.
final adminSeedDataState = AdminDataState(
  orders: initialAdminOrders,
  masters: initialAdminMasters,
  clients: initialAdminClients,
  chats: initialAdminChats,
  reviews: initialAdminReviews,
  transactions: initialAdminTransactions,
  settings: const SaPlatformSettings(),
  supportTickets: const [],
  categories: const [],
  coupons: const [],
  marketingLogs: const [],
);
