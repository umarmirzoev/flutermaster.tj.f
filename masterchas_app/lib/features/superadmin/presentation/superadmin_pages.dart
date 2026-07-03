import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/platform_models.dart';
import '../../../core/providers/platform_store_provider.dart';
import '../data/superadmin_data.dart';
import '../providers/superadmin_provider.dart';
import '../theme/superadmin_theme.dart';
import 'widgets/superadmin_forms.dart';
import 'widgets/superadmin_widgets.dart';

class SaListPage extends ConsumerWidget {
  const SaListPage({super.key, required this.title, required this.builder, this.action});

  final String title;
  final Widget Function(BuildContext context, WidgetRef ref) builder;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: SuperAdminTheme.text))),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          builder(context, ref),
        ],
      ),
    );
  }
}

Widget _addBtn(String label, VoidCallback onTap) => ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(LucideIcons.plus, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.green, foregroundColor: Colors.white),
    );

Future<String?> _prompt(BuildContext context, String title, {String hint = '', String initial = ''}) async {
  final ctrl = TextEditingController(text: initial);
  final v = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('OK')),
      ],
    ),
  );
  ctrl.dispose();
  return v;
}

// ─── Fund (благотворительность) ───────────────────────────────────────────────

class SaFundPage extends ConsumerStatefulWidget {
  const SaFundPage({super.key});

  @override
  ConsumerState<SaFundPage> createState() => _SaFundPageState();
}

class _SaFundPageState extends ConsumerState<SaFundPage> {
  final _orgNameCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  var _orgType = charityOrganizationTypes.first;

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _problemCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(platformStoreProvider);
    final store = ref.read(platformStoreProvider.notifier);
    final revenue = data.monthlyRevenue;
    final fund = data.charityFundAmount;
    final spent = data.charityFundSpent;
    final reserved = data.charityFundReserved;
    final available = data.charityFundAvailable;

    return SaListPage(
      title: 'Благотворительный фонд',
      builder: (context, ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SaCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.heart_handshake, color: SuperAdminTheme.purple, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Фонд помощи', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(
                            '$charityFundPercent% от выручки платформы идёт на ремонт и замену сломанного в детских центрах-сиротах и домах престарелых.',
                            style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.muted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final cw = w > 900 ? (w - 36) / 4 : w > 500 ? (w - 12) / 2 : w;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(width: cw, child: SaKpiCard(label: 'Выручка за месяц', value: '${formatSaMoney(revenue)} с.', change: '${data.orders.where((o) => o.status == SaOrderStatus.completed).length} заказов', icon: LucideIcons.wallet, iconColor: SuperAdminTheme.green, iconBg: const Color(0xFFD1FAE5))),
                SizedBox(width: cw, child: SaKpiCard(label: 'В фонд ($charityFundPercent%)', value: '${formatSaMoney(fund)} с.', change: 'от выручки', icon: LucideIcons.heart, iconColor: SuperAdminTheme.purple, iconBg: const Color(0xFFEDE9FE))),
                SizedBox(width: cw, child: SaKpiCard(label: 'Исправлено', value: '${formatSaMoney(spent)} с.', change: reserved > 0 ? 'В работе: ${formatSaMoney(reserved)} с.' : 'выполнено', icon: LucideIcons.wrench, iconColor: SuperAdminTheme.blue, iconBg: const Color(0xFFDBEAFE))),
                SizedBox(width: cw, child: SaKpiCard(label: 'Доступно', value: '${formatSaMoney(available)} с.', change: available >= 0 ? 'можно направить' : 'нужно пополнить', icon: LucideIcons.piggy_bank, iconColor: available >= 0 ? SuperAdminTheme.green : SuperAdminTheme.red, iconBg: available >= 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), positive: available >= 0)),
              ],
            );
          }),
          const SizedBox(height: 16),
          SaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Сообщить о поломке', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Опишите, что сломано — мастера платформы помогут починить за счёт фонда.', style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.muted)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _orgType,
                  decoration: const InputDecoration(labelText: 'Тип учреждения', border: OutlineInputBorder()),
                  items: charityOrganizationTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _orgType = v ?? _orgType),
                ),
                const SizedBox(height: 10),
                TextField(controller: _orgNameCtrl, decoration: const InputDecoration(labelText: 'Название учреждения', border: OutlineInputBorder(), hintText: 'Напр. Детский дом №3')),
                const SizedBox(height: 10),
                TextField(controller: _problemCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Что сломано?', border: OutlineInputBorder(), hintText: 'Сломан холодильник, протечка крана...')),
                const SizedBox(height: 10),
                TextField(controller: _costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Примерная стоимость ремонта (с.)', border: OutlineInputBorder())),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = _orgNameCtrl.text.trim();
                    final problem = _problemCtrl.text.trim();
                    final cost = int.tryParse(_costCtrl.text.trim()) ?? 0;
                    if (name.isEmpty || problem.isEmpty || cost <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
                      return;
                    }
                    store.addCharityCase(organizationType: _orgType, organizationName: name, problem: problem, estimatedCost: cost);
                    _orgNameCtrl.clear();
                    _problemCtrl.clear();
                    _costCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка добавлена в фонд')));
                  },
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Добавить заявку'),
                  style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Заявки на ремонт (${data.charityCases.length})', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (data.charityCases.isEmpty)
            const SaCard(child: Padding(padding: EdgeInsets.all(24), child: Text('Заявок пока нет. Добавьте первую — когда появятся выполненные заказы, фонд начнёт наполняться.')))
          else
            SaCard(
              child: Column(
                children: data.charityCases.map((c) {
                  final statusColor = c.status == 'Исправлено' ? SuperAdminTheme.green : c.status == 'В работе' ? SuperAdminTheme.yellow : SuperAdminTheme.blue;
                  return ListTile(
                    leading: Icon(c.organizationType == 'Детский центр' ? LucideIcons.baby : LucideIcons.house, color: SuperAdminTheme.purple),
                    title: Text(c.organizationName, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    subtitle: Text('${c.organizationType} · ${c.problem}\n${formatSaMoney(c.estimatedCost)} с. · ${c.date}', maxLines: 3),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => store.updateCharityCaseStatus(c.id, v),
                      itemBuilder: (_) => ['Ожидает', 'В работе', 'Исправлено'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                      child: SaStatusPill(label: c.status, color: statusColor),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Orders ───────────────────────────────────────────────────────────────────

class SaOrdersPage extends ConsumerWidget {
  const SaOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(platformStoreProvider).orders;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Заказы',
      action: _addBtn('Добавить заказ', () async {
        final client = await _prompt(context, 'Клиент');
        final master = await _prompt(context, 'Мастер');
        final service = await _prompt(context, 'Услуга');
        final amount = await _prompt(context, 'Сумма (с.)');
        if (client != null && client.isNotEmpty && service != null && service.isNotEmpty) {
          store.addOrder(client: client, master: master ?? '—', service: service, amount: int.tryParse(amount ?? '') ?? 0);
        }
      }),
      builder: (_, __) => orders.isEmpty
          ? const SaCard(child: Padding(padding: EdgeInsets.all(24), child: Text('Заказов пока нет. Нажмите «Добавить заказ».')))
          : SaCard(
              child: Column(
                children: orders.map((o) => ListTile(
                  title: Text('${o.id} — ${o.client}', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  subtitle: Text('${o.service} · ${o.master} · ${o.date}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SaStatusPill(label: saOrderStatusLabel(o.status), color: saOrderStatusColor(o.status)),
                      PopupMenuButton<SaOrderStatus>(
                        icon: const Icon(LucideIcons.ellipsis, size: 16),
                        onSelected: (s) => store.updateOrderStatus(o.id, s),
                        itemBuilder: (_) => SaOrderStatus.values.map((s) => PopupMenuItem(value: s, child: Text(saOrderStatusLabel(s)))).toList(),
                      ),
                      IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removeOrder(o.id)),
                    ],
                  ),
                )).toList(),
              ),
            ),
    );
  }
}

// ─── Masters / Clients / Shop / Products ──────────────────────────────────────

class SaMastersPage extends ConsumerWidget {
  const SaMastersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masters = ref.watch(platformStoreProvider).masters;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Мастера',
      action: _addBtn('Добавить мастера', () => showAddMasterSheet(context, ref)),
      builder: (_, __) => SaCard(
        child: Column(
          children: masters.map((m) => ListTile(
            leading: SaMasterAvatar(master: m),
            title: Text(m.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            subtitle: Text('${m.specialization} · ${m.phone} · ${m.orders} заказов'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.star, size: 14, color: Color(0xFFFFC107)),
              Text(' ${m.rating}'),
              IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removeMaster(m.id)),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}

class SaClientsPage extends ConsumerWidget {
  const SaClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(platformStoreProvider).clients;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Клиенты',
      action: _addBtn('Добавить клиента', () async {
        final name = await _prompt(context, 'Имя клиента');
        final phone = await _prompt(context, 'Телефон');
        if (name != null && name.isNotEmpty && phone != null && phone.isNotEmpty) store.addClient(name: name, phone: phone);
      }),
      builder: (_, __) => clients.isEmpty
          ? const SaCard(child: Padding(padding: EdgeInsets.all(24), child: Text('Клиентов пока нет.')))
          : SaCard(
              child: Column(
                children: clients.map((u) => ListTile(
                  leading: CircleAvatar(backgroundImage: AssetImage(u.avatar)),
                  title: Text(u.name),
                  subtitle: Text('${u.phone} · Регистрация: ${u.date}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (u.isVip) const SaStatusPill(label: 'VIP', color: SuperAdminTheme.yellow),
                    if (u.isNew) const SaStatusPill(label: 'Новый', color: SuperAdminTheme.blue),
                    IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removeClient(u.id)),
                  ]),
                )).toList(),
              ),
            ),
    );
  }
}

class SaShopPage extends ConsumerWidget {
  const SaShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(platformStoreProvider).products;
    return SaListPage(
      title: 'Магазин',
      action: _addBtn('Добавить товар', () => showAddProductSheet(context, ref)),
      builder: (_, __) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: products.map((p) => SizedBox(
          width: 220,
          child: SaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: SaProductImage(product: p, size: 80)),
                const SizedBox(height: 8),
                Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2),
                if (p.description.isNotEmpty) Text(p.description, style: GoogleFonts.inter(fontSize: 11, color: SuperAdminTheme.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('${formatSaMoney(p.price)} с.', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: SuperAdminTheme.green)),
                SaStatusPill(label: p.inStock ? 'В наличии' : 'Нет', color: p.inStock ? SuperAdminTheme.green : SuperAdminTheme.red),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class SaProductsPage extends ConsumerWidget {
  const SaProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(platformStoreProvider).products;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Товары',
      action: _addBtn('Добавить товар', () => showAddProductSheet(context, ref)),
      builder: (_, __) => SaCard(
        child: Column(
          children: products.map((p) => ListTile(
            leading: SaProductImage(product: p, size: 40),
            title: Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            subtitle: Text('${p.category} · ${p.description.isNotEmpty ? p.description : 'Продано: ${p.sold}'}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Switch(value: p.inStock, activeThumbColor: SuperAdminTheme.green, onChanged: (_) => store.toggleProductStock(p.id)),
              IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removeProduct(p.id)),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}

// ─── Categories / Brands / Coupons ──────────────────────────────────────────

class SaCategoriesPage extends ConsumerWidget {
  const SaCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(platformStoreProvider).categories;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Категории',
      action: _addBtn('Добавить', () async {
        final name = await _prompt(context, 'Название категории');
        if (name != null && name.isNotEmpty) store.addCategory(name);
      }),
      builder: (_, __) => SaCard(
        child: Column(
          children: cats.map((c) => ListTile(
            leading: Icon(LucideIcons.layers, size: 18, color: SuperAdminTheme.green),
            title: Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('${c.productCount} товаров'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Switch(value: c.active, activeThumbColor: SuperAdminTheme.green, onChanged: (v) => store.updateCategory(c.id, active: v)),
              IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removeCategory(c.id)),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}

class SaBrandsPage extends ConsumerWidget {
  const SaBrandsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(platformStoreProvider).brands;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Бренды',
      action: _addBtn('Добавить бренд', () async {
        final name = await _prompt(context, 'Название бренда');
        if (name != null && name.isNotEmpty) store.addBrand(name);
      }),
      builder: (_, __) => SaCard(
        child: Column(
          children: brands.map((b) => ListTile(
            leading: const Icon(LucideIcons.tag, size: 18, color: SuperAdminTheme.green),
            title: Text(b.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('${b.productCount} товаров'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Switch(value: b.active, activeThumbColor: SuperAdminTheme.green, onChanged: (v) => store.updateBrand(b.id, active: v)),
              IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removeBrand(b.id)),
            ]),
          )).toList(),
        ),
      ),
    );
  }
}

class SaCouponsPage extends ConsumerStatefulWidget {
  const SaCouponsPage({super.key});

  @override
  ConsumerState<SaCouponsPage> createState() => _SaCouponsPageState();
}

class _SaCouponsPageState extends ConsumerState<SaCouponsPage> {
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _discount = 10;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coupons = ref.watch(platformStoreProvider).coupons;
    final store = ref.read(platformStoreProvider.notifier);

    return SaListPage(
      title: 'Промокоды',
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Создать промокод', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Промокод', border: OutlineInputBorder(), hintText: 'MASTER20'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Описание (необязательно)', border: OutlineInputBorder(), hintText: 'Скидка на первый заказ'),
                ),
                const SizedBox(height: 14),
                Text('Скидка', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [5, 10, 20].map((pct) {
                    final on = _discount == pct;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$pct%'),
                        selected: on,
                        selectedColor: SuperAdminTheme.green.withValues(alpha: 0.2),
                        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, color: on ? SuperAdminTheme.green : SuperAdminTheme.text),
                        onSelected: (_) => setState(() => _discount = pct),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final code = _codeCtrl.text.trim().toUpperCase();
                    if (code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите промокод')));
                      return;
                    }
                    store.addCoupon(code: code, description: _descCtrl.text.trim().isEmpty ? 'Скидка $_discount%' : _descCtrl.text.trim(), discountPercent: _discount);
                    _codeCtrl.clear();
                    _descCtrl.clear();
                    setState(() => _discount = 10);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Промокод $code создан (−$_discount%)')));
                  },
                  icon: const Icon(LucideIcons.ticket, size: 16),
                  label: Text('Создать промокод (−$_discount%)'),
                  style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (coupons.isEmpty)
            const SaCard(child: Padding(padding: EdgeInsets.all(24), child: Text('Промокодов пока нет.')))
          else
            SaCard(
              child: Column(
                children: coupons.map((c) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: SuperAdminTheme.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text('−${c.discountPercent}%', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: SuperAdminTheme.green, fontSize: 13)),
                  ),
                  title: Text(c.code, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                  subtitle: Text(c.description.isNotEmpty ? c.description : 'Скидка ${c.discountPercent}%'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Switch(value: c.active, activeThumbColor: SuperAdminTheme.green, onChanged: (v) => store.updateCoupon(c.id, active: v)),
                    IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removeCoupon(c.id)),
                  ]),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Chats ────────────────────────────────────────────────────────────────────

class SaChatsPage extends ConsumerStatefulWidget {
  const SaChatsPage({super.key});

  @override
  ConsumerState<SaChatsPage> createState() => _SaChatsPageState();
}

class _SaChatsPageState extends ConsumerState<SaChatsPage> {
  String? _selected;
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(platformStoreProvider).chats;
    final store = ref.read(platformStoreProvider.notifier);
    final selected = _selected ?? (chats.isNotEmpty ? chats.first.id : null);
    SaChatThread? thread;
    if (selected != null) {
      for (final c in chats) {
        if (c.id == selected) {
          thread = c;
          break;
        }
      }
    }

    return SaListPage(
      title: 'Чаты',
      action: _addBtn('Новый чат', () async {
        final name = await _prompt(context, 'Имя клиента');
        if (name != null && name.isNotEmpty) store.addChat(name: name);
      }),
      builder: (_, __) => chats.isEmpty
          ? const SaCard(child: Padding(padding: EdgeInsets.all(24), child: Text('Чатов нет.')))
          : SizedBox(
              height: 480,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: SaCard(
                      child: ListView(
                        children: chats.map((c) {
                          final on = c.id == selected;
                          return ListTile(
                            selected: on,
                            onTap: () {
                              setState(() => _selected = c.id);
                              store.markChatRead(c.id);
                            },
                            leading: CircleAvatar(child: Text(c.avatar)),
                            title: Text(c.name),
                            subtitle: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: c.unread > 0 ? SaStatusPill(label: '${c.unread}', color: SuperAdminTheme.red) : Text(c.time, style: GoogleFonts.inter(fontSize: 11, color: SuperAdminTheme.muted)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: SaCard(
                      padding: const EdgeInsets.all(16),
                      child: thread == null
                          ? const Center(child: Text('Выберите чат'))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Чат с ${thread.name}', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ListView(
                                    children: thread.messages.map((m) => Align(
                                      alignment: m.isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: m.isAdmin ? SuperAdminTheme.green.withValues(alpha: 0.15) : SuperAdminTheme.pageBg, borderRadius: BorderRadius.circular(10)),
                                        child: Text(m.text),
                                      ),
                                    )).toList(),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(child: TextField(controller: _msgCtrl, decoration: const InputDecoration(hintText: 'Сообщение...', border: OutlineInputBorder()))),
                                    IconButton(
                                      icon: const Icon(LucideIcons.send, color: SuperAdminTheme.green),
                                      onPressed: () {
                                        final t = _msgCtrl.text.trim();
                                        if (t.isEmpty || selected == null) return;
                                        store.sendChatMessage(selected!, t);
                                        _msgCtrl.clear();
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Reviews / Finance / Analytics / Marketing ────────────────────────────────

class SaReviewsPage extends ConsumerWidget {
  const SaReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(platformStoreProvider).reviews;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Отзывы',
      action: _addBtn('Добавить', () async {
        final author = await _prompt(context, 'Автор');
        final master = await _prompt(context, 'Мастер');
        final text = await _prompt(context, 'Текст отзыва');
        final rating = await _prompt(context, 'Оценка 1-5', initial: '5');
        if (author != null && text != null) store.addReview(author: author, master: master ?? '', rating: int.tryParse(rating ?? '') ?? 5, text: text);
      }),
      builder: (_, __) => reviews.isEmpty
          ? const SaCard(child: Padding(padding: EdgeInsets.all(24), child: Text('Отзывов нет.')))
          : SaCard(
              child: Column(
                children: reviews.map((r) => ListTile(
                  leading: CircleAvatar(child: Text(r.avatar)),
                  title: Text('${r.author} → ${r.master}'),
                  subtitle: Text(r.text),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    ...List.generate(r.rating, (_) => const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFC107))),
                    IconButton(icon: Icon(r.hidden ? LucideIcons.eye : LucideIcons.eye_off, size: 16), onPressed: () => store.toggleReviewHidden(r.id)),
                    IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removeReview(r.id)),
                  ]),
                )).toList(),
              ),
            ),
    );
  }
}

class SaFinancePage extends ConsumerWidget {
  const SaFinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(platformStoreProvider);
    final store = ref.read(platformStoreProvider.notifier);
    final income = data.totalOrderAmount;
    final paidOut = data.payouts.where((p) => p.paid).fold(0, (a, p) => a + p.amount);
    return SaListPage(
      title: 'Финансы',
      action: _addBtn('Добавить выплату', () async {
        final master = await _prompt(context, 'Мастер');
        final amount = await _prompt(context, 'Сумма');
        if (master != null && master.isNotEmpty) store.addPayout(master: master, amount: int.tryParse(amount ?? '') ?? 0, method: 'Humo', paid: false);
      }),
      builder: (_, __) => Column(
        children: [
          Row(children: [
            Expanded(child: SaKpiCard(label: 'Доход (выполнено)', value: '${formatSaMoney(income)} с.', change: '${data.orders.where((o) => o.status == SaOrderStatus.completed).length} заказов', icon: LucideIcons.wallet, iconColor: SuperAdminTheme.green, iconBg: const Color(0xFFD1FAE5))),
            const SizedBox(width: 12),
            Expanded(child: SaKpiCard(label: 'Выплачено', value: '${formatSaMoney(paidOut)} с.', change: '${data.payouts.length} выплат', icon: LucideIcons.banknote, iconColor: SuperAdminTheme.blue, iconBg: const Color(0xFFDBEAFE))),
          ]),
          const SizedBox(height: 12),
          SaBarChartCard(title: 'Выплаты', points: computeIncomeChart(data.payouts)),
          const SizedBox(height: 12),
          SaCard(
            child: data.payouts.isEmpty
                ? const Padding(padding: EdgeInsets.all(24), child: Text('Выплат нет. Добавьте первую.'))
                : Column(
                    children: data.payouts.map((p) => ListTile(
                      title: Text(p.master),
                      subtitle: Text('${p.method} · ${p.date}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${formatSaMoney(p.amount)} с.', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: SuperAdminTheme.green)),
                        Switch(value: p.paid, activeThumbColor: SuperAdminTheme.green, onChanged: (_) => store.togglePayoutPaid(p.id)),
                        IconButton(icon: const Icon(LucideIcons.trash_2, size: 16, color: SuperAdminTheme.red), onPressed: () => store.removePayout(p.id)),
                      ]),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class SaAnalyticsPage extends ConsumerWidget {
  const SaAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(platformStoreProvider);
    final orderChart = computeOrdersChart(data.orders);
    final incomeChart = computeIncomeChart(data.payouts);
    final masterSlices = data.masters.isEmpty
        ? const [SaPieSlice(label: 'Нет данных', value: 1, color: SuperAdminTheme.muted, percent: 100)]
        : [
            SaPieSlice(label: 'Активные', value: data.masters.length.toDouble(), color: SuperAdminTheme.green, percent: 100),
          ];
    return SaListPage(
      title: 'Аналитика',
      builder: (_, __) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(width: 400, child: SaLineChartCard(title: 'Заказы', points: orderChart, color: SuperAdminTheme.green)),
          SizedBox(width: 400, child: SaBarChartCard(title: 'Выплаты', points: incomeChart)),
          SizedBox(width: 400, child: SaPieChartCard(title: 'Мастера', slices: masterSlices, total: '${data.masters.length}')),
          SizedBox(width: 400, child: SaKpiCard(label: 'Товары', value: '${data.products.length}', change: 'Клиентов: ${data.clients.length}', icon: LucideIcons.package, iconColor: SuperAdminTheme.purple, iconBg: const Color(0xFFEDE9FE))),
        ],
      ),
    );
  }
}

class SaMarketingPage extends ConsumerStatefulWidget {
  const SaMarketingPage({super.key});

  @override
  ConsumerState<SaMarketingPage> createState() => _SaMarketingPageState();
}

class _SaMarketingPageState extends ConsumerState<SaMarketingPage> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(platformStoreProvider).marketingLogs;
    final clients = ref.watch(platformStoreProvider).clients.length;
    final recipients = clients > 0 ? clients : 1;
    return SaListPage(
      title: 'Маркетинг',
      builder: (_, __) => Column(
        children: [
          SaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Рассылка ($recipients получателей)', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(controller: _msgCtrl, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Текст рассылки...')),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final text = _msgCtrl.text.trim();
                    if (text.isEmpty) return;
                    ref.read(platformStoreProvider.notifier).sendMarketing(text, recipients);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Рассылка отправлена $recipients пользователям')));
                    _msgCtrl.clear();
                  },
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('Отправить'),
                  style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.green, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SaCard(
            child: logs.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Text('История рассылок пуста.'))
                : Column(children: logs.map((l) => ListTile(title: Text(l.text, maxLines: 2), subtitle: Text('${l.sentAt} · ${l.recipients} чел.'))).toList()),
          ),
        ],
      ),
    );
  }
}

// ─── Pages CMS / Notifications / Support / Settings / System ──────────────────

class SaPagesPage extends ConsumerWidget {
  const SaPagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(platformStoreProvider).cmsPages;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Страницы',
      action: _addBtn('Добавить страницу', () async {
        final title = await _prompt(context, 'Название страницы');
        if (title != null && title.isNotEmpty) store.addCmsPage(title);
      }),
      builder: (_, __) => SaCard(
        child: Column(
          children: pages.map((p) => ListTile(
            leading: const Icon(LucideIcons.file_text, size: 18, color: SuperAdminTheme.green),
            title: Text(p.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(p.status),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => store.updateCmsPage(p.id, status: v),
              itemBuilder: (_) => ['Опубликована', 'Черновик'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

class SaNotificationsPage extends ConsumerWidget {
  const SaNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(platformStoreProvider).notifications;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Уведомления',
      action: TextButton(onPressed: () => store.markAllNotificationsRead(), child: const Text('Прочитать все')),
      builder: (_, __) => items.isEmpty
          ? const SaCard(child: Padding(padding: EdgeInsets.all(24), child: Text('Уведомлений нет.')))
          : SaCard(
              child: Column(
                children: items.map((n) => ListTile(
                  leading: Icon(n.icon, color: n.color),
                  title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w400 : FontWeight.w700)),
                  subtitle: Text(n.time),
                  onTap: () => store.markNotificationRead(n.id),
                )).toList(),
              ),
            ),
    );
  }
}

class SaSupportPage extends ConsumerWidget {
  const SaSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(platformStoreProvider).supportTickets;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Поддержка',
      action: _addBtn('Новый тикет', () async {
        final title = await _prompt(context, 'Тема');
        final desc = await _prompt(context, 'Описание');
        if (title != null && title.isNotEmpty) store.addSupportTicket(title: title, description: desc ?? '');
      }),
      builder: (_, __) => tickets.isEmpty
          ? const SaCard(child: Padding(padding: EdgeInsets.all(24), child: Text('Тикетов нет.')))
          : SaCard(
              child: Column(
                children: tickets.map((t) => ListTile(
                  title: Text(t.id, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  subtitle: Text('${t.title}\n${t.description}', maxLines: 2),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => store.updateTicketStatus(t.id, v),
                    itemBuilder: (_) => ['Открыт', 'В работе', 'Закрыт'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                    child: SaStatusPill(label: t.status, color: t.status == 'Открыт' ? SuperAdminTheme.red : t.status == 'В работе' ? SuperAdminTheme.yellow : SuperAdminTheme.green),
                  ),
                )).toList(),
              ),
            ),
    );
  }
}

class SaSettingsPage extends ConsumerStatefulWidget {
  const SaSettingsPage({super.key});

  @override
  ConsumerState<SaSettingsPage> createState() => _SaSettingsPageState();
}

class _SaSettingsPageState extends ConsumerState<SaSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(platformStoreProvider).settings;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Настройки',
      builder: (_, __) => SaCard(
        child: Column(
          children: [
            SwitchListTile(title: const Text('Режим обслуживания'), value: s.maintenance, onChanged: (v) => store.updateSettings(SaPlatformSettings(maintenance: v, registrations: s.registrations, commissionPercent: s.commissionPercent, pushNotifications: s.pushNotifications, autoApproveMasters: s.autoApproveMasters)), activeThumbColor: SuperAdminTheme.green),
            SwitchListTile(title: const Text('Регистрация'), value: s.registrations, onChanged: (v) => store.updateSettings(SaPlatformSettings(maintenance: s.maintenance, registrations: v, commissionPercent: s.commissionPercent, pushNotifications: s.pushNotifications, autoApproveMasters: s.autoApproveMasters)), activeThumbColor: SuperAdminTheme.green),
            SwitchListTile(title: const Text('Push-уведомления'), value: s.pushNotifications, onChanged: (v) => store.updateSettings(SaPlatformSettings(maintenance: s.maintenance, registrations: s.registrations, commissionPercent: s.commissionPercent, pushNotifications: v, autoApproveMasters: s.autoApproveMasters)), activeThumbColor: SuperAdminTheme.green),
            ListTile(title: Text('Комиссия: ${s.commissionPercent}%'), trailing: IconButton(icon: const Icon(LucideIcons.pencil), onPressed: () async {
              final v = await _prompt(context, 'Комиссия %', initial: '${s.commissionPercent}');
              final pct = int.tryParse(v ?? '');
              if (pct != null) store.updateSettings(SaPlatformSettings(maintenance: s.maintenance, registrations: s.registrations, commissionPercent: pct, pushNotifications: s.pushNotifications, autoApproveMasters: s.autoApproveMasters));
            })),
            ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены'))), style: ElevatedButton.styleFrom(backgroundColor: SuperAdminTheme.green, foregroundColor: Colors.white), child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}

class SaSystemPage extends ConsumerWidget {
  const SaSystemPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(platformStoreProvider).systemServices;
    final store = ref.read(platformStoreProvider.notifier);
    return SaListPage(
      title: 'Система',
      builder: (_, __) => SaCard(
        child: Column(
          children: [
            for (final s in services)
              ListTile(
                leading: Icon(s.status == 'Работает' ? LucideIcons.circle_check : LucideIcons.circle_alert, color: s.status == 'Работает' ? SuperAdminTheme.green : SuperAdminTheme.yellow),
                title: Text(s.name),
                subtitle: Text(s.detail),
                trailing: Text(s.status, style: GoogleFonts.inter(color: SuperAdminTheme.green, fontWeight: FontWeight.w600)),
                onTap: () => store.updateSystemService(s.name, s.status == 'Работает' ? 'Проверка' : 'Работает', s.detail),
              ),
          ],
        ),
      ),
    );
  }
}
