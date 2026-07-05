import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/home_strings.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers/locale_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/models/api_order.dart';
import '../../orders/utils/address_validator.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/order_workflow_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../services/data/services_catalog.dart';
import '../data/masters_data.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({
    super.key,
    required this.master,
    this.serviceName,
    this.serviceTitleRu,
    this.servicePrice,
  });

  final MasterItem master;
  final String? serviceName;
  final String? serviceTitleRu;
  final double? servicePrice;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  static const _times = [
    '09:00', '11:00', '13:00', '15:00', '17:00', '19:00',
  ];

  late final List<DateTime> _days;
  int _dayIndex = 0;
  int _timeIndex = 2;
  final _addressCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(14, (i) => DateTime(today.year, today.month, today.day + i));
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      !_isSubmitting &&
      _addressCtrl.text.trim().isNotEmpty &&
      AddressValidator.isValid(_addressCtrl.text);

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = HomeStrings.of(locale);
    final p = HomePalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultService = defaultServiceForMaster(widget.master);
    final displayServiceName = widget.serviceName ??
        widget.serviceTitleRu ??
        defaultService?.ru ??
        widget.master.categories.first;

    return ColoredBox(
      color: p.shellBg,
      child: Center(
        child: Container(
          width: 390,
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height),
          decoration: BoxDecoration(
            color: p.pageBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            backgroundColor: p.pageBg,
            body: SafeArea(
              child: Column(
                children: [
                  _Header(s: s, p: p),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _MasterSummary(
                          m: widget.master,
                          serviceName: displayServiceName,
                          p: p,
                        ),
                        const SizedBox(height: 20),
                        _SectionTitle(s.chooseDate, p),
                        const SizedBox(height: 10),
                        _DatePicker(
                          days: _days,
                          selected: _dayIndex,
                          s: s,
                          p: p,
                          onSelect: (i) => setState(() => _dayIndex = i),
                        ),
                        const SizedBox(height: 20),
                        _SectionTitle(s.chooseTime, p),
                        const SizedBox(height: 10),
                        _TimePicker(
                          times: _times,
                          selected: _timeIndex,
                          p: p,
                          onSelect: (i) => setState(() => _timeIndex = i),
                        ),
                        const SizedBox(height: 20),
                        _SectionTitle(s.addressTitle, p),
                        const SizedBox(height: 10),
                        _AddressField(controller: _addressCtrl, s: s, p: p, onChanged: () => setState(() {})),
                        if (_addressCtrl.text.trim().isNotEmpty &&
                            !AddressValidator.isValid(_addressCtrl.text)) ...[
                          const SizedBox(height: 8),
                          Text(
                            AddressValidator.invalidMessage,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade700),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _SectionTitle(s.commentTitle, p),
                        const SizedBox(height: 10),
                        _CommentField(controller: _commentCtrl, s: s, p: p),
                      ],
                    ),
                  ),
                  _ConfirmBar(
                    s: s,
                    p: p,
                    enabled: _canConfirm,
                    onConfirm: _confirm,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final s = HomeStrings.of(ref.read(localeProvider));
    final defaultService = defaultServiceForMaster(widget.master);
    final apiTitle = widget.serviceTitleRu ??
        widget.serviceName ??
        defaultService?.ru ??
        widget.master.categories.first;
    final serviceName = apiTitle;
    final repo = ref.read(ordersRepositoryProvider);
    final address = _addressCtrl.text.trim();

    if (!AddressValidator.isValid(address)) {
      setState(() {
        _isSubmitting = false;
        _error = AddressValidator.invalidMessage;
      });
      return;
    }

    try {
      final resolved = await repo.resolveServiceByTitle(serviceName);
      if (resolved == null || resolved.id.isEmpty) {
        throw Exception('Услуга «$serviceName» не найдена на сервере');
      }

      double price = widget.servicePrice ??
          defaultService?.priceAvg.toDouble() ??
          widget.master.priceMin.toDouble();
      if (widget.servicePrice == null) {
        for (final cat in serviceCatalog) {
          for (final item in cat.services) {
            if (item.ru == serviceName) {
              price = item.priceAvg.toDouble();
              break;
            }
          }
        }
      }

      final date = _days[_dayIndex];
      final time = _times[_timeIndex];
      final result = await repo.createOrder(
        serviceId: resolved.id,
        title: resolved.title,
        description: _commentCtrl.text.trim().isEmpty
            ? 'Заказ мастеру ${widget.master.fullName}'
            : _commentCtrl.text.trim(),
        address: address,
        price: price,
        masterPhone: widget.master.phone,
        scheduledDate: date,
        scheduledTime: '$time:00',
      );

      if (result is! ApiSuccess<ApiOrder>) {
        final message = switch (result) {
          ApiError<ApiOrder>(:final message) => message,
          _ => result.toString(),
        };
        throw Exception(message);
      }

      final order = result.data;

      final auth = ref.read(authProvider);
      await ref.read(orderWorkflowProvider.notifier).registerOrder(
            order: order,
            clientName: auth.displayName ?? 'Клиент',
            clientPhone: auth.phone ?? '',
            masterName: widget.master.fullName,
            masterPhone: widget.master.phone,
            scheduledDate: date,
            scheduledTime: '$time:00',
          );

      ref.invalidate(clientOrdersProvider);
      ref.invalidate(mergedClientOrdersProvider);
      ref.invalidate(mergedMasterOrdersProvider);

      if (!mounted) return;

      if (order.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              order.statusCode == 7 || order.statusCode == 8
                  ? AddressValidator.invalidMessage
                  : 'Заказ отменён сервером',
            ),
          ),
        );
        return;
      }

      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _SuccessSheet(
          s: s,
          master: widget.master,
          date: date,
          time: time,
          address: _addressCtrl.text.trim(),
          onClose: () {
            Navigator.pop(ctx);
            Navigator.of(context).maybePop();
          },
        ),
      );
    } catch (e, st) {
      debugPrint('BOOKING ERROR: $e');
      debugPrint('BOOKING STACK: $st');
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        setState(() => _error = message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.s, required this.p});

  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Material(
            color: p.cardBg,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.border),
                ),
                child: Icon(LucideIcons.arrow_left, size: 18, color: p.text),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            s.bookingTitle,
            style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: p.text),
          ),
        ],
      ),
    );
  }
}

class _MasterSummary extends StatelessWidget {
  const _MasterSummary({required this.m, required this.serviceName, required this.p});

  final MasterItem m;
  final String? serviceName;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: m.imageBytes != null
                ? Image.memory(m.imageBytes!, width: 52, height: 52, fit: BoxFit.cover)
                : Image.asset(m.image, width: 52, height: 52, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.text),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.badge_check, size: 14, color: Color(0xFF2F80ED)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  serviceName ?? m.categories.first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: brandGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.p);

  final String title;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({
    required this.days,
    required this.selected,
    required this.s,
    required this.p,
    required this.onSelect,
  });

  final List<DateTime> days;
  final int selected;
  final HomeStrings s;
  final HomePalette p;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = days[i];
          final on = i == selected;
          final wd = s.weekdaysShort[d.weekday - 1];
          return Material(
            color: on ? brandGreen : p.cardBg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: on ? brandGreen : p.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      wd,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: on ? Colors.white.withValues(alpha: 0.9) : p.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: on ? Colors.white : p.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.monthsShort[d.month - 1],
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: on ? Colors.white.withValues(alpha: 0.85) : p.muted,
                      ),
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

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.times,
    required this.selected,
    required this.p,
    required this.onSelect,
  });

  final List<String> times;
  final int selected;
  final HomePalette p;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(times.length, (i) {
        final on = i == selected;
        return Material(
          color: on ? brandGreen : p.cardBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 102,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: on ? brandGreen : p.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.clock, size: 14, color: on ? Colors.white : p.muted),
                  const SizedBox(width: 6),
                  Text(
                    times[i],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : p.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.s,
    required this.p,
    required this.onChanged,
  });

  final TextEditingController controller;
  final HomeStrings s;
  final HomePalette p;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.map_pin, size: 18, color: brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              cursorColor: brandGreen,
              style: GoogleFonts.inter(fontSize: 13.5, color: p.text),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: InputBorder.none,
                hintText: s.addressHint,
                hintStyle: GoogleFonts.inter(fontSize: 13.5, color: p.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller, required this.s, required this.p});

  final TextEditingController controller;
  final HomeStrings s;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        cursorColor: brandGreen,
        style: GoogleFonts.inter(fontSize: 13.5, color: p.text, height: 1.4),
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
          hintText: s.commentHint,
          hintStyle: GoogleFonts.inter(fontSize: 13.5, color: p.muted, height: 1.4),
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.s,
    required this.p,
    required this.enabled,
    required this.onConfirm,
  });

  final HomeStrings s;
  final HomePalette p;
  final bool enabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: p.cardBg,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: brandGreen.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              s.confirmBtn,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.s,
    required this.master,
    required this.date,
    required this.time,
    required this.address,
    required this.onClose,
  });

  final HomeStrings s;
  final MasterItem master;
  final DateTime date;
  final String time;
  final String address;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: brandGreen.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.circle_check, size: 38, color: brandGreen),
            ),
            const SizedBox(height: 16),
            Text(
              s.bookingDone,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text, height: 1.35),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.pageBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _row(LucideIcons.user, master.fullName, p),
                  const SizedBox(height: 8),
                  _row(
                    LucideIcons.calendar,
                    '${s.weekdaysShort[date.weekday - 1]}, ${date.day} ${s.monthsShort[date.month - 1]} · $time',
                    p,
                  ),
                  const SizedBox(height: 8),
                  _row(LucideIcons.map_pin, address, p),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, HomePalette p) {
    return Row(
      children: [
        Icon(icon, size: 16, color: brandGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: p.text),
          ),
        ),
      ],
    );
  }
}
