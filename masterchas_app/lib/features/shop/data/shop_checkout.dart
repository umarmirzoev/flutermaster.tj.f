import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_result.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/models/api_order.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../orders/utils/address_validator.dart';
import '../../profile/presentation/profile_subpages.dart' show PaymentMethodsPage;
import '../../../core/widgets/motion.dart';
import '../data/shop_data.dart';
import '../providers/shop_admin_orders_provider.dart';
import '../state/shop_state.dart';

/// Показывает форму адреса и оформляет заказ в профиль + админ-панель (+ API при входе).
Future<bool> completeShopCheckout({
  required BuildContext context,
  required WidgetRef ref,
  required Map<int, int> items,
  required int total,
  required int discount,
  required List<ShopProduct> catalog,
  required ShopL10n l,
  String kind = 'Магазин',
  bool clearCart = false,
}) async {
  if (items.isEmpty || total <= 0) return false;

  final address = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ShopAddressSheet(l: l),
  );

  if (address == null || address.trim().isEmpty) return false;
  if (!context.mounted) return false;

  // Как будете платить: наличными или одной из сохранённых карт.
  final payment = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PaymentMethodSheet(total: total, unit: l.priceUnit),
  );
  if (payment == null) return false;
  if (!context.mounted) return false;

  final orderId = 'SH-${DateTime.now().millisecondsSinceEpoch}';
  final bonus = (total * 0.01).round();
  final order = ShopOrder(
    id: orderId,
    date: DateTime.now(),
    items: Map<int, int>.from(items),
    total: total,
    discount: discount,
    bonus: bonus,
    address: address.trim(),
    paymentMethod: payment,
  );

  await ref.read(shopOrdersProvider.notifier).add(order);
  await ref.read(shopAdminOrdersProvider.notifier).registerPurchase(
        items: order.items,
        total: order.total,
        catalog: catalog,
        kind: kind,
        address: order.address,
        orderId: order.id,
      );

  final productsLine = items.entries
      .where((e) => e.key >= 0 && e.key < catalog.length)
      .map((e) {
        final p = catalog[e.key];
        return e.value <= 1 ? p.ru : '${p.ru} ×${e.value}';
      })
      .join(', ');

  final auth = ref.read(authProvider);
  if (auth.isAuthenticated) {
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final resolved = await repo.resolveServiceByTitle('Другие услуги');
      if (resolved != null && resolved.id.isNotEmpty) {
        final apiResult = await repo.createOrder(
          serviceId: resolved.id,
          title: '$kind: $productsLine',
          description: 'Заказ товаров из магазина Master.tj. Оплата: $payment',
          address: order.address,
          price: total.toDouble(),
        );
        if (apiResult is ApiSuccess<ApiOrder>) {
          await ref.read(orderWorkflowProvider.notifier).registerOrder(
                order: apiResult.data,
                clientName: auth.displayName ?? 'Клиент',
                clientPhone: auth.phone ?? '',
                masterName: 'Магазин',
                masterPhone: '',
              );
          ref.invalidate(clientOrdersProvider);
          ref.invalidate(mergedClientOrdersProvider);
        }
      }
    } catch (_) {}
  }

  if (clearCart) {
    ref.read(shopCartProvider.notifier).clear();
  }
  ref.invalidate(adminDataProvider);

  if (!context.mounted) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: brandGreen,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${l.orderPlaced} · $payment',
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  return true;
}

class _ShopAddressSheet extends ConsumerStatefulWidget {
  const _ShopAddressSheet({required this.l});

  final ShopL10n l;

  @override
  ConsumerState<_ShopAddressSheet> createState() => _ShopAddressSheetState();
}

class _ShopAddressSheetState extends ConsumerState<_ShopAddressSheet> {
  late final TextEditingController _addressCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController();
    Future.microtask(() async {
      await ref.read(shopAddressesProvider.notifier).ensureLoaded();
      if (!mounted) return;
      final saved = ref.read(shopAddressesProvider.notifier).lastUsed;
      if (saved != null && saved.isNotEmpty) {
        _addressCtrl.text = saved;
      }
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final address = _addressCtrl.text.trim();
    if (!AddressValidator.isValid(address)) {
      setState(() => _error = AddressValidator.invalidMessage);
      return;
    }
    ref.read(shopAddressesProvider.notifier).add(
          ShopAddress(
            title: 'Доставка',
            city: '',
            street: address,
            details: '',
            comment: '',
          ),
        );
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.l.deliveryAddress,
                style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
              ),
              const SizedBox(height: 6),
              Text(
                widget.l.deliveryAddressSub,
                style: GoogleFonts.manrope(fontSize: 13, color: p.muted, height: 1.35),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressCtrl,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: widget.l.addressHint,
                  errorText: _error,
                  prefixIcon: const Icon(LucideIcons.map_pin, color: brandGreen),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: brandGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    widget.l.checkout,
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Выбор способа оплаты: наличные или сохранённая карта (можно сразу добавить новую).
class _PaymentMethodSheet extends ConsumerStatefulWidget {
  const _PaymentMethodSheet({required this.total, required this.unit});

  final int total;
  final String unit;

  @override
  ConsumerState<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends ConsumerState<_PaymentMethodSheet> {
  static const _cash = 'Наличными';
  String _selected = _cash;

  String _cardLabel(PaymentCard c) => 'Картой ${c.brand} •• ${c.last4}';

  Future<void> _addCard() async {
    final before = ref.read(shopCardsProvider).length;
    await Navigator.of(context).push(SmoothRoute<void>(builder: (_) => const PaymentMethodsPage()));
    if (!mounted) return;
    final cards = ref.read(shopCardsProvider);
    // Только что добавленную карту сразу выбираем.
    if (cards.length > before) setState(() => _selected = _cardLabel(cards.last));
  }

  Widget _option({
    required HomePalette p,
    required String value,
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    int index = 0,
  }) {
    final selected = _selected == value;
    return Reveal(
      delay: Duration(milliseconds: 40 + 60 * index),
      offsetY: 12,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: HoverLift(
          radius: 16,
          lift: 2,
          scale: 1.01,
          glowColor: color,
          child: GestureDetector(
            onTap: () => setState(() => _selected = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.08) : p.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? color : p.border, width: selected ? 1.8 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.text)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle, style: GoogleFonts.manrope(fontSize: 11.5, color: p.muted)),
                        ],
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Icon(
                      selected ? LucideIcons.circle_check : LucideIcons.circle,
                      key: ValueKey(selected),
                      color: selected ? color : p.muted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    final cards = ref.watch(shopCardsProvider);
    var i = 0;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      decoration: BoxDecoration(
        color: p.pageBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Как будете оплачивать?', style: GoogleFonts.manrope(fontSize: 19, fontWeight: FontWeight.w800, color: p.text)),
                  const Spacer(),
                  const Icon(LucideIcons.wallet, color: brandGreen, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _option(
                    p: p,
                    index: i++,
                    value: _cash,
                    icon: LucideIcons.banknote,
                    color: brandGreen,
                    title: 'Наличными при получении',
                    subtitle: 'Оплата курьеру или мастеру',
                  ),
                  for (final c in cards)
                    _option(
                      p: p,
                      index: i++,
                      value: _cardLabel(c),
                      icon: LucideIcons.credit_card,
                      color: const Color(0xFF3B82F6),
                      title: '${c.brand} •• ${c.last4}',
                      subtitle: '${c.holder.isEmpty ? 'Карта' : c.holder} · до ${c.expiry}',
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextButton.icon(
                      onPressed: _addCard,
                      icon: const Icon(LucideIcons.plus, size: 18, color: brandGreen),
                      label: Text(
                        cards.isEmpty ? 'Добавить карту' : 'Добавить другую карту',
                        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: brandGreen),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(color: p.cardBg, border: Border(top: BorderSide(color: p.border))),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Подтвердить заказ · ${shopMoney(widget.total)} ${widget.unit}',
                    style: GoogleFonts.manrope(fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
