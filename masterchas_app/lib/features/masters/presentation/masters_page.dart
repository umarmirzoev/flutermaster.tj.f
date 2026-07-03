import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/home_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../../core/providers/catalog_provider.dart';
import '../data/masters_data.dart';
import 'ai_master_picker_sheet.dart';
import 'master_detail_page.dart';

class MastersPage extends ConsumerStatefulWidget {
  const MastersPage({super.key, this.initialFilter});

  /// Master-category key (Russian) to pre-filter the list, or null for "Все".
  final String? initialFilter;

  @override
  ConsumerState<MastersPage> createState() => _MastersPageState();
}

class _MastersPageState extends ConsumerState<MastersPage> {
  String? _filter; // null == "Все"
  final _favorites = <String>{};

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilter;
    _filter = f == null ? null : resolveMasterCategory(f);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = HomeStrings.of(locale);
    final p = HomePalette.of(context);

    final allMasters = ref.watch(mastersCatalogProvider);
    final list = _filter == null
        ? allMasters
        : allMasters.where((m) => m.categories.contains(_filter)).toList();

    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(s: s, p: p),
            _FilterChips(
              s: s,
              p: p,
              locale: locale,
              selected: _filter,
              onSelect: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _AiPickCard(s: s, p: p, onPick: () => showAiMasterPickerSheet(context)),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(LucideIcons.users, size: 44, color: p.muted),
                            const SizedBox(height: 12),
                            Text(
                              s.nothingFoundMasters,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...list.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _MasterListCard(
                          m: m,
                          s: s,
                          p: p,
                          locale: locale,
                          isFav: _favorites.contains(m.fullName),
                          onFav: () => setState(() {
                            if (!_favorites.add(m.fullName)) {
                              _favorites.remove(m.fullName);
                            }
                          }),
                          onOpen: () => _openDetail(m),
                          onCall: () => _showCall(m, s),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(MasterItem m) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MasterDetailPage(master: m)),
    );
  }

  void _showCall(MasterItem m, HomeStrings s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: brandGreen,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(LucideIcons.phone, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${m.fullName} · ${m.phone}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          Expanded(
            child: Center(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${s.mastersWord} ',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                      ),
                    ),
                    TextSpan(
                      text: s.nearWord,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: brandGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _BellButton(p: p),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.p});

  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: p.border),
            ),
            child: Icon(LucideIcons.bell, size: 17, color: p.text),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
              child: Text(
                '3',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.s,
    required this.p,
    required this.locale,
    required this.selected,
    required this.onSelect,
  });

  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = <(String?, String, IconData)>[
      (null, s.all, LucideIcons.layout_grid),
      ('Электрика', localizedCategory('Электрика', locale), LucideIcons.zap),
      ('Сантехника', localizedCategory('Сантехника', locale), LucideIcons.droplet),
      ('Мебель и двери', s.catFurniture, LucideIcons.armchair),
      ('Отделка', s.catFinishing, LucideIcons.paint_roller),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label, icon) = chips[i];
          final on = key == selected;
          return Material(
            color: on ? brandGreen : p.cardBg,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => onSelect(key),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: on ? brandGreen : p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: on ? Colors.white : p.muted),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: on ? Colors.white : p.text,
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

class _AiPickCard extends StatelessWidget {
  const _AiPickCard({required this.s, required this.p, required this.onPick});

  final HomeStrings s;
  final HomePalette p;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF12241B) : const Color(0xFFEFF7EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.sparkles, size: 14, color: brandGreen),
                    const SizedBox(width: 5),
                    Text(
                      s.aiPickBadge,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: brandGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.aiPickTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.aiPickSub,
                  style: GoogleFonts.inter(fontSize: 11, color: p.muted, height: 1.35),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onPick,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(LucideIcons.sparkles, size: 16),
                    label: Text(
                      s.aiPickBtn,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            height: 84,
            child: Image.asset('assets/images/home_ai_robot.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _MasterListCard extends StatelessWidget {
  const _MasterListCard({
    required this.m,
    required this.s,
    required this.p,
    required this.locale,
    required this.isFav,
    required this.onFav,
    required this.onOpen,
    required this.onCall,
  });

  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final bool isFav;
  final VoidCallback onFav;
  final VoidCallback onOpen;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: light ? 1.5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Photo(m: m, s: s),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: _Info(m: m, s: s, p: p, locale: locale, isFav: isFav, onFav: onFav),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: p.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.fromPrice} ${_money(m.priceMin)} ${s.priceUnit}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: brandGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ChatBtn(s: s, onTap: onOpen),
                    const SizedBox(width: 8),
                    _CallBtn(s: s, onTap: onCall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _money(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return buf.toString();
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.m, required this.s});

  final MasterItem m;
  final HomeStrings s;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (m.imageBytes != null)
            Image.memory(m.imageBytes!, fit: BoxFit.cover, alignment: Alignment.topCenter)
          else
            Image.asset(m.image, fit: BoxFit.cover, alignment: Alignment.topCenter),
          if (m.isOnline)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      s.onlineWord,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.m,
    required this.s,
    required this.p,
    required this.locale,
    required this.isFav,
    required this.onFav,
  });

  final MasterItem m;
  final HomeStrings s;
  final HomePalette p;
  final AppLocale locale;
  final bool isFav;
  final VoidCallback onFav;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      m.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.badge_check, size: 15, color: Color(0xFF2F80ED)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(LucideIcons.star, size: 14, color: Color(0xFFFFC107)),
            const SizedBox(width: 2),
            Text(
              m.rating.toStringAsFixed(1),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: p.text),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            Expanded(
              child: Text(
                m.profession(locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: brandGreen,
                ),
              ),
            ),
            Text(
              '(${m.reviews} ${s.reviewsWord})',
              style: GoogleFonts.inter(fontSize: 10.5, color: p.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Tag(icon: LucideIcons.shield_check, label: s.badgeVerified, filled: false, p: p),
            if (m.isTop) _Tag(icon: LucideIcons.star, label: s.badgeTop, filled: true, p: p),
            _Tag(
              icon: LucideIcons.car,
              label: '${s.arrivalPrefix} 20 ${s.minShort}',
              filled: false,
              p: p,
              neutral: true,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${s.expWord} ${m.experienceYears}+ ${s.yearsShort}  ·  ${s.completedWord}: ${m.completedOrders}+',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 10.5, color: p.muted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _MiniAvatars(),
            const SizedBox(width: 8),
            Row(
              children: List.generate(
                5,
                (_) => const Padding(
                  padding: EdgeInsets.only(right: 1),
                  child: Icon(LucideIcons.star, size: 11, color: Color(0xFFFFC107)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniAvatars extends StatelessWidget {
  const _MiniAvatars();

  @override
  Widget build(BuildContext context) {
    const imgs = [
      'assets/images/master_1.png',
      'assets/images/master_2.png',
      'assets/images/master_3.png',
    ];
    return SizedBox(
      width: 52,
      height: 20,
      child: Stack(
        children: [
          for (var i = 0; i < imgs.length; i++)
            Positioned(
              left: i * 15.0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  image: DecorationImage(image: AssetImage(imgs[i]), fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
    required this.filled,
    required this.p,
    this.neutral = false,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final HomePalette p;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (filled) {
      bg = brandGreen;
      fg = Colors.white;
    } else if (neutral) {
      bg = p.muted.withValues(alpha: 0.12);
      fg = p.text;
    } else {
      bg = brandGreen.withValues(alpha: 0.12);
      fg = brandGreen;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

class _ChatBtn extends StatelessWidget {
  const _ChatBtn({required this.s, required this.onTap});

  final HomeStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(LucideIcons.message_circle, size: 15),
        label: Text(
          s.chatBtn,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CallBtn extends StatelessWidget {
  const _CallBtn({required this.s, required this.onTap});

  final HomeStrings s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: brandGreen,
          side: const BorderSide(color: brandGreen),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(LucideIcons.phone, size: 15),
        label: Text(
          s.callBtn,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
