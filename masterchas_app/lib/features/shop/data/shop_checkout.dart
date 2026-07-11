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
          description: 'Заказ товаров из магазина Master.tj',
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
          l.orderPlaced,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
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
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
              ),
              const SizedBox(height: 6),
              Text(
                widget.l.deliveryAddressSub,
                style: GoogleFonts.inter(fontSize: 13, color: p.muted, height: 1.35),
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
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
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
