import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/providers/locale_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../shop/data/shop_data.dart';
import '../../shop/state/shop_state.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../masters/data/masters_data.dart';
import '../../masters/presentation/master_detail_page.dart';
import '../../masters/providers/master_favorites_provider.dart';
import '../data/profile_l10n.dart';
import 'change_password_page.dart';
import 'profile_shell.dart';

// ─── Payment methods ─────────────────────────────────────────────────────────

class PaymentMethodsPage extends ConsumerStatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  ConsumerState<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends ConsumerState<PaymentMethodsPage> {
  final _numCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  bool _showForm = false;

  @override
  void dispose() {
    _numCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  void _save(ProfileL10n l) {
    final digits = _numCtrl.text.replaceAll(RegExp(r'\D'), '');
    final exp = _expCtrl.text.trim();
    if (digits.length != 16 || !RegExp(r'^\d{2}/\d{2}$').hasMatch(exp) || _cvvCtrl.text.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.invalidCard)));
      return;
    }
    ref.read(shopCardsProvider.notifier).add(
          PaymentCard(number: digits, holder: _holderCtrl.text.trim(), expiry: exp),
        );
    _numCtrl.clear();
    _expCtrl.clear();
    _cvvCtrl.clear();
    _holderCtrl.clear();
    setState(() => _showForm = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: brandGreen, content: Text(l.cardSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = ProfileL10n.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);
    final cards = ref.watch(shopCardsProvider);

    return ProfileSubPage(
      title: l.paymentMethods,
      floatingActionButton: !_showForm
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showForm = true),
              backgroundColor: brandGreen,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              label: Text(l.addCard, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_showForm) ...[
            _CardPreview(number: _numCtrl.text, expiry: _expCtrl.text, holder: _holderCtrl.text),
            const SizedBox(height: 16),
            profileField(
              p: p,
              label: l.cardNumber,
              controller: _numCtrl,
              keyboard: TextInputType.number,
              maxLength: 19,
              formatters: [_CardNumberFormatter()],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: profileField(
                    p: p,
                    label: l.expiry,
                    controller: _expCtrl,
                    keyboard: TextInputType.number,
                    maxLength: 5,
                    formatters: [_ExpiryFormatter()],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: profileField(
                    p: p,
                    label: l.cvv,
                    controller: _cvvCtrl,
                    keyboard: TextInputType.number,
                    maxLength: 3,
                    obscure: true,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            profileField(p: p, label: l.holder, controller: _holderCtrl),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showForm = false),
                    child: Text('OK', style: GoogleFonts.inter(color: p.muted)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _save(l),
                    style: ElevatedButton.styleFrom(backgroundColor: brandGreen, foregroundColor: Colors.white),
                    child: Text(l.save, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (cards.isEmpty && !_showForm)
            _EmptyBox(icon: LucideIcons.credit_card, text: l.emptyCards, p: p)
          else
            ...List.generate(cards.length, (i) {
              final c = cards[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: c.brand == 'VISA'
                        ? [const Color(0xFF1A1F71), const Color(0xFF2D3A8C)]
                        : [const Color(0xFF2B2F36), const Color(0xFF3C434D)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c.brand, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => ref.read(shopCardsProvider.notifier).removeAt(i),
                          icon: const Icon(LucideIcons.trash_2, color: Colors.white70, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '•••• •••• •••• ${c.last4}',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Text('${c.holder}  ·  ${c.expiry}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.number, required this.expiry, required this.holder});

  final String number;
  final String expiry;
  final String holder;

  @override
  Widget build(BuildContext context) {
    final display = number.isEmpty ? '•••• •••• •••• ••••' : number.padRight(19, '•');
    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF2E9E4F), Color(0xFF57B55E)]),
        boxShadow: [BoxShadow(color: brandGreen.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.credit_card, color: Colors.white, size: 28),
          const Spacer(),
          Text(display, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(holder.isEmpty ? 'NAME' : holder.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, color: Colors.white))),
              Text(expiry.isEmpty ? 'MM/YY' : expiry, style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 16) return o;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return TextEditingValue(text: buf.toString(), selection: TextSelection.collapsed(offset: buf.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var d = n.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) return o;
    if (d.length >= 3) d = '${d.substring(0, 2)}/${d.substring(2)}';
    return TextEditingValue(text: d, selection: TextSelection.collapsed(offset: d.length));
  }
}

// ─── Addresses ───────────────────────────────────────────────────────────────

class AddressesPage extends ConsumerStatefulWidget {
  const AddressesPage({super.key});

  @override
  ConsumerState<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends ConsumerState<AddressesPage> {
  final _titleCtrl = TextEditingController(text: 'Дом');
  final _cityCtrl = TextEditingController(text: 'Душанбе');
  final _streetCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _showForm = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cityCtrl.dispose();
    _streetCtrl.dispose();
    _detailsCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _save(ProfileL10n l) {
    if (_streetCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) return;
    ref.read(shopAddressesProvider.notifier).add(
          ShopAddress(
            title: _titleCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            street: _streetCtrl.text.trim(),
            details: _detailsCtrl.text.trim(),
            comment: _commentCtrl.text.trim(),
          ),
        );
    _streetCtrl.clear();
    _detailsCtrl.clear();
    _commentCtrl.clear();
    setState(() => _showForm = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: brandGreen, content: Text(l.addressSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = ProfileL10n.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);
    final addrs = ref.watch(shopAddressesProvider);

    return ProfileSubPage(
      title: l.myAddresses,
      floatingActionButton: !_showForm
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showForm = true),
              backgroundColor: brandGreen,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              label: Text(l.addAddress, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_showForm) ...[
            profileField(p: p, label: l.addressTitle, controller: _titleCtrl),
            const SizedBox(height: 12),
            profileField(p: p, label: l.city, controller: _cityCtrl),
            const SizedBox(height: 12),
            profileField(p: p, label: l.street, controller: _streetCtrl),
            const SizedBox(height: 12),
            profileField(p: p, label: l.details, controller: _detailsCtrl),
            const SizedBox(height: 12),
            profileField(p: p, label: l.comment, controller: _commentCtrl, maxLines: 2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _save(l),
                style: ElevatedButton.styleFrom(backgroundColor: brandGreen, foregroundColor: Colors.white),
                child: Text(l.save, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (addrs.isEmpty && !_showForm)
            _EmptyBox(icon: LucideIcons.map_pin, text: l.emptyAddresses, p: p)
          else
            ...List.generate(addrs.length, (i) {
              final a = addrs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: brandGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                      child: const Icon(LucideIcons.map_pin, size: 18, color: brandGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
                          const SizedBox(height: 4),
                          Text(a.oneLine, style: GoogleFonts.inter(fontSize: 13, color: p.text, height: 1.3)),
                          if (a.comment.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(a.comment, style: GoogleFonts.inter(fontSize: 11.5, color: p.muted, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(shopAddressesProvider.notifier).removeAt(i),
                      icon: Icon(LucideIcons.trash_2, size: 18, color: p.muted),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Security & Notifications ────────────────────────────────────────────────

class SecurityPage extends ConsumerWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ProfileL10n.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);
    final s = ref.watch(shopSecuritySettingsProvider);
    final n = ref.read(shopSecuritySettingsProvider.notifier);

    return ProfileSubPage(
      title: l.security,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToggleTile(p: p, icon: LucideIcons.fingerprint_pattern, label: l.biometric, value: s['biometric'] ?? false, onChanged: () => n.toggle('biometric')),
          _ToggleTile(p: p, icon: LucideIcons.lock, label: l.pinLock, value: s['pin'] ?? false, onChanged: () => n.toggle('pin')),
          _ToggleTile(p: p, icon: LucideIcons.shield, label: l.twofa, value: s['twofa'] ?? false, onChanged: () => n.toggle('twofa')),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage()),
              ),
              icon: Icon(LucideIcons.key_round, color: p.text),
              label: Text(l.changePin, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: p.text)),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ProfileL10n.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);
    final s = ref.watch(shopNotifSettingsProvider);
    final n = ref.read(shopNotifSettingsProvider.notifier);

    return ProfileSubPage(
      title: l.notifications,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToggleTile(p: p, icon: LucideIcons.bell, label: l.pushNotif, value: s['push'] ?? true, onChanged: () => n.toggle('push')),
          _ToggleTile(p: p, icon: LucideIcons.mail, label: l.emailNotif, value: s['email'] ?? false, onChanged: () => n.toggle('email')),
          _ToggleTile(p: p, icon: LucideIcons.smartphone, label: l.smsNotif, value: s['sms'] ?? true, onChanged: () => n.toggle('sms')),
          _ToggleTile(p: p, icon: LucideIcons.tag, label: l.promoNotif, value: s['promos'] ?? true, onChanged: () => n.toggle('promos')),
          _ToggleTile(p: p, icon: LucideIcons.package, label: l.orderNotif, value: s['orders'] ?? true, onChanged: () => n.toggle('orders')),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.p, required this.icon, required this.label, required this.value, required this.onChanged});

  final HomePalette p;
  final IconData icon;
  final String label;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: p.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: brandGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: p.text))),
          Switch(value: value, activeTrackColor: brandGreen, onChanged: (_) => onChanged()),
        ],
      ),
    );
  }
}

// ─── Support ─────────────────────────────────────────────────────────────────

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  final _msgCtrl = TextEditingController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = ProfileL10n.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);

    return ProfileSubPage(
      title: l.support,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.phone, size: 18),
                  label: Text(l.callSupport),
                  style: ElevatedButton.styleFrom(backgroundColor: brandGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(l.writeSupport, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 10),
          profileField(p: p, label: '', controller: _msgCtrl, maxLines: 4),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (_msgCtrl.text.trim().isEmpty) return;
                _msgCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: brandGreen, content: Text(l.messageSent)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white),
              child: Text(l.send, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 24),
          Text(l.faqTitle, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 10),
          _FaqTile(q: l.faq1q, a: l.faq1a, p: p),
          _FaqTile(q: l.faq2q, a: l.faq2a, p: p),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.q, required this.a, required this.p});

  final String q;
  final String a;
  final HomePalette p;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: widget.p.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: widget.p.border)),
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.q, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: widget.p.text))),
                  Icon(_open ? LucideIcons.chevron_up : LucideIcons.chevron_down, size: 18, color: widget.p.muted),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 8),
                Text(widget.a, style: GoogleFonts.inter(fontSize: 13, color: widget.p.muted, height: 1.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Favorites ───────────────────────────────────────────────────────────────

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l = ProfileL10n.of(locale);
    final p = HomePalette.of(context);
    final favKeys = ref.watch(masterFavoritesProvider);
    final allMasters = ref.watch(mastersCatalogProvider);
    final masters = allMasters.where((m) => favKeys.contains(m.fullName)).toList();

    return ProfileSubPage(
      title: l.favorites,
      body: masters.isEmpty
          ? _EmptyBox(icon: LucideIcons.heart, text: 'Добавьте мастеров в избранное', p: p)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: masters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = masters[i];
                return Material(
                  color: p.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => MasterDetailPage(master: m)),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(m.image, width: 56, height: 56, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: p.text)),
                                const SizedBox(height: 2),
                                Text(m.profession(locale), style: GoogleFonts.inter(fontSize: 12, color: brandGreen)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => ref.read(masterFavoritesProvider.notifier).remove(m.fullName),
                            icon: const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Orders ──────────────────────────────────────────────────────────────────

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l = ProfileL10n.of(locale);
    final p = HomePalette.of(context);
    final orders = ref.watch(shopOrdersProvider);

    return ProfileSubPage(
      title: l.orderHistory,
      body: orders.isEmpty
          ? _EmptyBox(icon: LucideIcons.shopping_bag, text: l.emptyOrders, p: p)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final o = orders[i];
                final date = '${o.date.day.toString().padLeft(2, '0')}.${o.date.month.toString().padLeft(2, '0')}.${o.date.year}';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: p.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(date, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
                          const Spacer(),
                          Text('${shopMoney(o.total)} ${l.unit}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: brandGreen)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${o.count} ${l.itemsWord}', style: GoogleFonts.inter(fontSize: 12, color: p.muted)),
                      if (o.address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(LucideIcons.map_pin, size: 13, color: brandGreen),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(o.address, style: GoogleFonts.inter(fontSize: 11.5, color: p.muted)),
                            ),
                          ],
                        ),
                      ],
                      if (o.discount > 0 || o.bonus > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (o.discount > 0)
                              _chip('-${shopMoney(o.discount)} ${l.discountWord}', const Color(0xFFEF4444)),
                            if (o.bonus > 0) ...[
                              const SizedBox(width: 8),
                              _chip('+${o.bonus} ${l.bonusWord}', brandGreen),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: o.items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, k) {
                            final e = o.items.entries.elementAt(k);
                            final pr = shopProducts[e.key];
                            return Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
                              child: Image.asset(pr.image, fit: BoxFit.contain),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _chip(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
      );
}

// ─── Spent (graph) ───────────────────────────────────────────────────────────

class SpentPage extends ConsumerWidget {
  const SpentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ProfileL10n.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);
    final orders = ref.watch(shopOrdersProvider);
    final notifier = ref.read(shopOrdersProvider.notifier);
    final spent = notifier.totalSpent;
    final discount = notifier.totalDiscount;
    final bonus = notifier.totalBonus;

    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final dayTotals = <DateTime, int>{for (final d in days) d: 0};
    final dayDiscount = <DateTime, int>{for (final d in days) d: 0};
    final dayBonus = <DateTime, int>{for (final d in days) d: 0};

    for (final o in orders) {
      final key = DateTime(o.date.year, o.date.month, o.date.day);
      if (dayTotals.containsKey(key)) {
        dayTotals[key] = dayTotals[key]! + o.total;
        dayDiscount[key] = dayDiscount[key]! + o.discount;
        dayBonus[key] = dayBonus[key]! + o.bonus;
      }
    }

    final maxVal = dayTotals.values.fold(1, (a, b) => a > b ? a : b);

    return ProfileSubPage(
      title: l.spentTitle,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(label: l.totalSpent, value: '${shopMoney(spent)} ${l.unit}', color: const Color(0xFFF59E0B), p: p)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(label: l.totalDiscount, value: '${shopMoney(discount)} ${l.unit}', color: const Color(0xFFEF4444), p: p)),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryCard(label: l.totalBonus, value: '+$bonus', color: brandGreen, p: p, wide: true),
          const SizedBox(height: 20),
          Text(l.chartTitle, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 14),
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(color: p.cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.border)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (dayTotals[d]! > 0)
                          Text('${shopMoney(dayTotals[d]!)}', style: GoogleFonts.inter(fontSize: 8, color: p.muted)),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 120 * (dayTotals[d]! / maxVal),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [brandGreen, brandGreen.withValues(alpha: 0.55)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${d.day}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: p.muted)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...orders.map((o) {
            final date = '${o.date.day.toString().padLeft(2, '0')}.${o.date.month.toString().padLeft(2, '0')}';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(date, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
                      const Spacer(),
                      Text('${shopMoney(o.total)} ${l.unit}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: p.text)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l.perDay}: ${shopMoney(o.total)} ${l.unit} · ${l.discountWord}: ${shopMoney(o.discount)} · ${l.bonusWord}: +${o.bonus}',
                    style: GoogleFonts.inter(fontSize: 11, color: p.muted, height: 1.35),
                  ),
                ],
              ),
            );
          }),
          if (orders.isEmpty) _EmptyBox(icon: LucideIcons.wallet, text: l.emptyOrders, p: p),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.color, required this.p, this.wide = false});

  final String label;
  final String value;
  final Color color;
  final HomePalette p;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
            child: Icon(LucideIcons.wallet, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: p.text)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: p.muted)),
        ],
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.prod,
    required this.locale,
    required this.p,
    required this.l,
    required this.onRemove,
    required this.onAdd,
    this.onOpen,
  });

  final ShopProduct prod;
  final AppLocale locale;
  final HomePalette p;
  final ProfileL10n l;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: p.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              color: Colors.white,
              padding: const EdgeInsets.all(6),
              child: Image.asset(prod.image, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prod.name(locale), maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
                  const SizedBox(height: 4),
                  Text('${shopMoney(prod.price)} ${l.unit}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: brandGreen)),
                ],
              ),
            ),
            IconButton(onPressed: onRemove, icon: const Icon(LucideIcons.heart, color: Color(0xFFEF4444), size: 20)),
            Material(
              color: brandGreen,
              shape: const CircleBorder(),
              child: InkWell(onTap: onAdd, customBorder: const CircleBorder(), child: const SizedBox(width: 34, height: 34, child: Icon(LucideIcons.plus, color: Colors.white, size: 18))),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.icon, required this.text, required this.p});

  final IconData icon;
  final String text;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: p.muted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: p.muted)),
          ],
        ),
      ),
    );
  }
}
