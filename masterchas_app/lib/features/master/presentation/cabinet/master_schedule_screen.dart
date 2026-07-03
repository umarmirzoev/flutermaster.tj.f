import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../auth/providers/auth_provider.dart';
import 'master_cabinet_shell.dart';

const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

class MasterScheduleScreen extends ConsumerStatefulWidget {
  const MasterScheduleScreen({super.key});

  @override
  ConsumerState<MasterScheduleScreen> createState() => _MasterScheduleScreenState();
}

class _MasterScheduleScreenState extends ConsumerState<MasterScheduleScreen> {
  Set<int> _days = {1, 2, 3, 4, 5};
  RangeValues _hours = const RangeValues(9, 18);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = ref.read(authProvider).masterProfile;
      if (!mounted) return;
      setState(() {
        _days = Set<int>.from(p?.scheduleWeekdays ?? [1, 2, 3, 4, 5]);
        _hours = RangeValues(
          (p?.scheduleFromHour ?? 9).toDouble(),
          (p?.scheduleToHour ?? 18).toDouble(),
        );
      });
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).updateMasterCabinet(
          (p) => p.copyWith(
            scheduleWeekdays: _days.toList()..sort(),
            scheduleFromHour: _hours.start.round(),
            scheduleToHour: _hours.end.round(),
          ),
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('График сохранён', style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterCabinetShell(
      title: 'Мой график',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Рабочие дни',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: masterNavy,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = _days.contains(day);
              return FilterChip(
                label: Text(_weekdays[i]),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _days.add(day);
                  } else {
                    _days.remove(day);
                  }
                }),
                selectedColor: masterNavy.withValues(alpha: 0.15),
                checkmarkColor: masterNavy,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: selected ? masterNavy : const Color(0xFF6B7280),
                ),
                side: BorderSide(
                  color: selected ? masterNavy : const Color(0xFFE8ECF1),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Text(
            'Часы работы: ${_hours.start.round()}:00 — ${_hours.end.round()}:00',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: masterNavy,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _hours,
            min: 6,
            max: 22,
            divisions: 16,
            activeColor: masterNavy,
            onChanged: (v) => setState(() => _hours = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving || _days.isEmpty ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: masterNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _saving ? 'Сохранение...' : 'Сохранить график',
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
