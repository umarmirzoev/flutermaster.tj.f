import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/home_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../profile/presentation/profile_shell.dart';
import '../data/masters_data.dart';
import '../models/master_review.dart';
import '../providers/master_reviews_provider.dart';

class MasterReviewsPage extends ConsumerStatefulWidget {
  const MasterReviewsPage({super.key, required this.master});

  final MasterItem master;

  @override
  ConsumerState<MasterReviewsPage> createState() => _MasterReviewsPageState();
}

class _MasterReviewsPageState extends ConsumerState<MasterReviewsPage> {
  final _bodyCtrl = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _bodyCtrl.text.trim();
    if (body.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Напишите отзыв хотя бы из 5 символов')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = ref.read(authProvider);
      await ref.read(masterReviewsProvider.notifier).addReview(
            masterKey: widget.master.fullName,
            authorName: auth.displayName ?? 'Клиент',
            rating: _rating,
            body: body,
            clientPhone: auth.phone,
          );
      _bodyCtrl.clear();
      setState(() => _rating = 5);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: brandGreen,
            content: Text('Отзыв добавлен'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = HomeStrings.of(locale);
    final p = HomePalette.of(context);
    final reviews = reviewsForMaster(ref, widget.master.fullName);
    final stats = reviewStatsForMaster(ref, widget.master.fullName, fallbackRating: widget.master.rating);

    return ProfileSubPage(
      title: s.reviewsTitle,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.star, color: Color(0xFFFFC107), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        stats.averageRating.toStringAsFixed(1),
                        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: p.text),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${stats.count} ${s.reviewsWord}',
                        style: GoogleFonts.inter(fontSize: 13, color: p.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('Отзывов пока нет', style: GoogleFonts.inter(color: p.muted)),
                    ),
                  )
                else
                  ...reviews.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReviewTile(review: r, p: p),
                      )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: p.cardBg,
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Добавить отзыв', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: p.text)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < _rating;
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => setState(() => _rating = i + 1),
                        icon: Icon(
                          filled ? LucideIcons.star : LucideIcons.star,
                          color: filled ? const Color(0xFFFFC107) : p.muted,
                          size: 24,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: _bodyCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Расскажите о работе мастера…',
                      hintStyle: GoogleFonts.inter(color: p.muted, fontSize: 13),
                      filled: true,
                      fillColor: p.pageBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: p.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: p.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: brandGreen),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Отправить', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
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

class AllReviewsPage extends ConsumerWidget {
  const AllReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = HomeStrings.of(locale);
    final p = HomePalette.of(context);
    final reviews = ref.watch(allMasterReviewsProvider);

    return ProfileSubPage(
      title: s.allReviews,
      body: reviews.isEmpty
          ? Center(child: Text('Отзывов пока нет', style: GoogleFonts.inter(color: p.muted)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ReviewTile(review: reviews[i], p: p, showMaster: true),
            ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.p,
    this.showMaster = false,
  });

  final MasterReview review;
  final HomePalette p;
  final bool showMaster;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: p.text),
                ),
              ),
              Text(review.dateLabel, style: GoogleFonts.inter(fontSize: 11, color: p.muted)),
            ],
          ),
          if (showMaster) ...[
            const SizedBox(height: 2),
            Text(review.masterKey, style: GoogleFonts.inter(fontSize: 11, color: brandGreen, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                LucideIcons.star,
                size: 13,
                color: i < review.rating ? const Color(0xFFFFC107) : p.muted.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(review.body, style: GoogleFonts.inter(fontSize: 13, color: p.text, height: 1.45)),
        ],
      ),
    );
  }
}
