import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/master_palette.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../services/data/service_catalog_keys.dart';
import '../../../services/data/services_catalog.dart';
import 'master_cabinet_shell.dart';

class MasterServicesScreen extends ConsumerStatefulWidget {
  const MasterServicesScreen({super.key});

  @override
  ConsumerState<MasterServicesScreen> createState() =>
      _MasterServicesScreenState();
}

class _MasterServicesScreenState extends ConsumerState<MasterServicesScreen> {
  late List<String> _services;
  late Map<String, int> _prices;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFromProfile();
  }

  void _loadFromProfile() {
    final profile = ref.read(authProvider).masterProfile;
    _services = List<String>.from(profile?.selectedServices ?? const []);
    _prices = Map<String, int>.from(profile?.servicePrices ?? const {});
    for (final key in _services) {
      _prices.putIfAbsent(key, () => defaultPriceForServiceKey(key));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateMasterServices(
            services: _services,
            prices: _prices,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Услуги сохранены', style: GoogleFonts.inter()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removeService(String key) {
    setState(() {
      _services.remove(key);
      _prices.remove(key);
    });
    _save();
  }

  void _updatePrice(String key, String value) {
    final price = int.tryParse(value.replaceAll(RegExp(r'\D'), ''));
    if (price == null || price <= 0) return;
    setState(() => _prices[key] = price);
  }

  Future<void> _showAddServiceSheet() async {
    final locale = ref.read(localeProvider);
    final selected = _services.toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Добавить услугу',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: masterNavy,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: serviceCatalog.length,
                    itemBuilder: (context, catIndex) {
                      final category = serviceCatalog[catIndex];
                      return ExpansionTile(
                        leading: Icon(category.icon, color: category.color),
                        title: Text(
                          category.name(locale),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        children: category.services.map((service) {
                          final key = serviceSelectionKey(category, service);
                          final alreadyAdded = selected.contains(key);
                          return ListTile(
                            title: Text(
                              service.name(locale),
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            subtitle: Text(
                              'от ${service.priceAvg} с.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            trailing: alreadyAdded
                                ? const Icon(LucideIcons.check, color: masterNavy)
                                : const Icon(LucideIcons.plus, color: masterNavy),
                            onTap: alreadyAdded
                                ? null
                                : () {
                                    setState(() {
                                      _services.add(key);
                                      _prices[key] = service.priceAvg;
                                    });
                                    Navigator.pop(context);
                                    _save();
                                  },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MasterCabinetShell(
      title: 'Мои услуги',
      actions: [
        IconButton(
          onPressed: _showAddServiceSheet,
          icon: const Icon(LucideIcons.plus, color: masterNavy),
          tooltip: 'Добавить услугу',
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving ? '...' : 'Сохранить',
            style: GoogleFonts.inter(
              color: masterNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      child: _services.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.wrench, size: 48, color: masterNavy),
                    const SizedBox(height: 16),
                    Text(
                      'Услуг пока нет',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: masterNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Добавьте услуги, которые вы выполняете, и укажите цены',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _showAddServiceSheet,
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Добавить услугу'),
                      style: FilledButton.styleFrom(
                        backgroundColor: masterNavy,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final key = _services[index];
                final found = lookupServiceByKey(key);
                final name = found?.service.name(locale) ?? key.split('::').last;
                final unit = found?.service.unitLabel(locale) ?? 'шт';
                final price = _prices[key] ?? defaultPriceForServiceKey(key);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8ECF1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: masterNavy,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeService(key),
                            icon: const Icon(
                              LucideIcons.trash_2,
                              size: 18,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      if (found != null)
                        Text(
                          found.category.name(locale),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(key),
                              initialValue: '$price',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) => _updatePrice(key, v),
                              onFieldSubmitted: (_) => _save(),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Цена за $unit',
                                suffixText: 'с.',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
