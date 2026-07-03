import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../auth/providers/auth_provider.dart';
import 'master_cabinet_shell.dart';

const dushanbeDistricts = [
  'Сино',
  'Шохмансур',
  'Фирдавси',
  'Исмоили Сомони',
];

class MasterWorkZoneScreen extends ConsumerStatefulWidget {
  const MasterWorkZoneScreen({super.key});

  @override
  ConsumerState<MasterWorkZoneScreen> createState() => _MasterWorkZoneScreenState();
}

class _MasterWorkZoneScreenState extends ConsumerState<MasterWorkZoneScreen> {
  Set<String> _selected = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selected = Set<String>.from(
          ref.read(authProvider).masterProfile?.workDistricts ?? const [],
        );
      });
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).updateMasterCabinet(
          (p) => p.copyWith(workDistricts: _selected.toList()),
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Зона работы сохранена', style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterCabinetShell(
      title: 'Зона работы',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: masterNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.map_pin, color: masterNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Выберите районы Душанбе, в которых вы готовы принимать заказы',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: masterNavy,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...dushanbeDistricts.map((district) {
            final isOn = _selected.contains(district);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOn ? masterNavy : const Color(0xFFE8ECF1),
                  width: isOn ? 1.5 : 1,
                ),
              ),
              child: CheckboxListTile(
                value: isOn,
                activeColor: masterNavy,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(district);
                  } else {
                    _selected.remove(district);
                  }
                }),
                title: Text(
                  district,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: masterNavy,
                  ),
                ),
                secondary: Icon(
                  LucideIcons.building_2,
                  color: isOn ? masterNavy : const Color(0xFF9CA3AF),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving || _selected.isEmpty ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: masterNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _saving ? 'Сохранение...' : 'Сохранить зону',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
