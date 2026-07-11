import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_design.dart';
import '../../home/presentation/home_palette.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Аукцион мастеров — клиент создаёт заявку, мастера предлагают цены.
/// Таймер обратного отсчёта. Клиент выбирает лучшее предложение.
/// ═══════════════════════════════════════════════════════════════════════════

class _Bid {
  _Bid({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.eta,
    required this.experience,
  });
  final String name;
  final double rating;
  final int reviews;
  final int price;
  final int eta;
  final int experience;
}

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key, this.serviceName = 'Ремонт услуга'});

  final String serviceName;

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  final _descController = TextEditingController();
  bool _started = false;
  int _secondsLeft = 30;
  Timer? _timer;
  final List<_Bid> _bids = [];

  static final _pool = [
    _Bid(name: 'Алишер Муродов', rating: 4.9, reviews: 127, price: 280, eta: 15, experience: 8),
    _Bid(name: 'Фаррух Рахимов', rating: 4.8, reviews: 89, price: 250, eta: 25, experience: 6),
    _Bid(name: 'Джамшед Каримов', rating: 5.0, reviews: 203, price: 320, eta: 10, experience: 12),
    _Bid(name: 'Бахтиёр Сафаров', rating: 4.7, reviews: 64, price: 220, eta: 30, experience: 5),
    _Bid(name: 'Нозим Ашуров', rating: 4.9, reviews: 156, price: 300, eta: 20, experience: 9),
  ];

  @override
  void dispose() {
    _descController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startAuction() {
    HapticFeedback.mediumImpact();
    setState(() {
      _started = true;
      _secondsLeft = 30;
      _bids.clear();
    });

    // Countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });

    // Bids arrive over time
    for (int i = 0; i < _pool.length; i++) {
      Future.delayed(Duration(milliseconds: 1200 + i * 1800), () {
        if (!mounted) return;
        HapticFeedback.lightImpact();
        setState(() {
          _bids.add(_pool[i]);
          _bids.sort((a, b) => a.price.compareTo(b.price));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return Scaffold(
      backgroundColor: p.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(p),
            Expanded(
              child: _started ? _buildAuction(p) : _buildForm(p),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(HomePalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(LucideIcons.arrow_left, color: p.text),
          ),
          Text(
            'Аукцион мастеров',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: p.text,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppDesign.goldGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.gavel, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Новинка',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(HomePalette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppDesign.goldGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppDesign.glowShadow(AppDesign.accentOrange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.gavel, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Пусть мастера борются\nза ваш заказ',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Опишите задачу — мастера предложат свои цены за 30 секунд. Выбирайте лучшую!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Опишите задачу',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: p.text,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: p.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: TextField(
              controller: _descController,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              cursorColor: AppDesign.brand,
              style: GoogleFonts.inter(fontSize: 14, color: p.text, height: 1.4),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                hintText: 'Например: нужно установить 3 розетки и повесить люстру в зале...',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: p.muted, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _infoRow(LucideIcons.clock, 'Аукцион длится 30 секунд', p),
          const SizedBox(height: 10),
          _infoRow(LucideIcons.users, 'Ваш заказ увидят все мастера рядом', p),
          const SizedBox(height: 10),
          _infoRow(LucideIcons.badge_percent, 'Конкуренция снижает цену на 15-30%', p),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Запустить аукцион',
            icon: LucideIcons.gavel,
            gradient: AppDesign.goldGradient,
            glowColor: AppDesign.accentOrange,
            enabled: _descController.text.trim().length >= 10,
            onPressed: _startAuction,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, HomePalette p) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppDesign.accentOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppDesign.accentOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: p.text),
          ),
        ),
      ],
    );
  }

  Widget _buildAuction(HomePalette p) {
    final done = _secondsLeft <= 0;
    return Column(
      children: [
        // Timer
        Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: done ? AppDesign.brandGradient : AppDesign.goldGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppDesign.glowShadow(
                done ? AppDesign.brand : AppDesign.accentOrange),
          ),
          child: Row(
            children: [
              Icon(done ? LucideIcons.circle_check : LucideIcons.clock,
                  color: Colors.white, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? 'Аукцион завершён' : 'Идёт аукцион',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      done
                          ? 'Выберите лучшее предложение'
                          : 'Осталось $_secondsLeft секунд',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (!done)
                Text(
                  '$_secondsLeft',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        // Bids counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Предложения',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppDesign.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_bids.length}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppDesign.brand,
                  ),
                ),
              ),
              const Spacer(),
              if (_bids.isNotEmpty)
                Text(
                  'сортировка: цена ↑',
                  style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _bids.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppDesign.accentOrange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Мастера изучают ваш заказ...',
                        style: GoogleFonts.inter(fontSize: 14, color: p.muted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _bids.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _bidCard(_bids[i], i == 0, done, p),
                ),
        ),
      ],
    );
  }

  Widget _bidCard(_Bid bid, bool isBest, bool done, HomePalette p) {
    return FadeSlideIn(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isBest ? AppDesign.brand : p.border,
            width: isBest ? 2 : 1,
          ),
          boxShadow: isBest ? AppDesign.brandGlow(intensity: 0.15) : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppDesign.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.user, color: Colors.white, size: 24),
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
                              bid.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: p.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.badge_check, size: 15, color: Color(0xFF2F80ED)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(LucideIcons.star, size: 13, color: Color(0xFFFFC107)),
                          const SizedBox(width: 3),
                          Text(
                            '${bid.rating} (${bid.reviews})',
                            style: GoogleFonts.inter(fontSize: 12, color: p.muted),
                          ),
                          const SizedBox(width: 10),
                          Icon(LucideIcons.briefcase, size: 12, color: p.muted),
                          const SizedBox(width: 3),
                          Text(
                            '${bid.experience} лет',
                            style: GoogleFonts.inter(fontSize: 12, color: p.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isBest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppDesign.brand,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ЛУЧШАЯ ЦЕНА',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Text(
                      '${bid.price} с.',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isBest ? AppDesign.brand : p.text,
                      ),
                    ),
                    Text(
                      'приедет ~${bid.eta} мин',
                      style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                    ),
                  ],
                ),
              ],
            ),
            if (done) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: isBest ? 'Выбрать этого мастера' : 'Выбрать',
                  height: 44,
                  icon: LucideIcons.check,
                  gradient: isBest
                      ? AppDesign.brandGradient
                      : LinearGradient(colors: [p.muted, p.muted]),
                  glowColor: isBest ? AppDesign.brand : p.muted,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppDesign.brand,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Мастер ${bid.name} выбран! Заказ оформлен.',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    );
                    Navigator.of(context).maybePop();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
