import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'onboarding_illustrations.dart';

const _onboardingGreen = Color(0xFF57B55E);
const _bodyTextColor = Color(0xFF6B7280);
const _inactiveDotColor = Color(0xFFD1D5DB);

class ClientOnboardingScreen extends StatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  State<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends State<ClientOnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _btnPulseController;

  static final _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      illustration: OnboardingIllustrations.nearbyMaster(),
      title: 'Мастер рядом с вами',
      description: 'Найдите нужного мастера через поиск — система подберёт подходящие анкеты. С помощью фильтров вы сможете выбрать мастеров в вашем городе и районе',
      icon: LucideIcons.map_pin,
      accent: _onboardingGreen,
    ),
    _OnboardingPageData(
      illustration: OnboardingIllustrations.ratingReviews(),
      title: 'Рейтинг и отзывы',
      description: 'Оценивайте работу специалистов и знакомьтесь с отзывами других клиентов. Чем больше положительных оценок, тем выше рейтинг специалиста',
      icon: LucideIcons.star,
      accent: const Color(0xFFF59E0B),
    ),
    _OnboardingPageData(
      illustration: OnboardingIllustrations.serviceRequest(),
      title: 'Оформите заявку на услугу',
      description: 'Оставьте заявку, и в ближайшие минуты специалисты сами свяжутся с вами и предложат свои услуги',
      icon: LucideIcons.file_text,
      accent: const Color(0xFF3B82F6),
    ),
    _OnboardingPageData(
      illustration: OnboardingIllustrations.compareCost(),
      title: 'Сопоставляйте стоимость',
      description: 'Просматривайте стоимость услуг и выбирайте наиболее подходящее предложение. Обязательно учитывайте рейтинг специалиста при выборе',
      icon: LucideIcons.scale,
      accent: const Color(0xFF8B5CF6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _btnPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _btnPulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _onActionPressed() {
    final isLastPage = _currentPage >= _pages.length - 1;
    if (isLastPage) {
      context.go('/login');
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar with step counter ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _pages[_currentPage].accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_pages[_currentPage].icon, size: 14, color: _pages[_currentPage].accent),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentPage + 1} из ${_pages.length}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _pages[_currentPage].accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!isLast)
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Пропустить',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _bodyTextColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Progress bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(_pages.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? _pages[_currentPage].accent
                              : _inactiveDotColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Pages ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => _OnboardingPageContent(data: _pages[index]),
              ),
            ),

            // ── Action button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: AnimatedBuilder(
                animation: _btnPulseController,
                builder: (context, child) {
                  final pulse = isLast ? _btnPulseController.value : 0.0;
                  return Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isLast
                            ? [const Color(0xFF4BAF50), _onboardingGreen, const Color(0xFF6DD674)]
                            : [_pages[_currentPage].accent, _pages[_currentPage].accent.withValues(alpha: 0.85)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _pages[_currentPage].accent.withValues(alpha: 0.25 + pulse * 0.15),
                          blurRadius: 16 + pulse * 8,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _onActionPressed,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLast ? 'Начать' : 'Далее',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLast ? LucideIcons.rocket : LucideIcons.arrow_right,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.illustration,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });
  final Widget illustration;
  final String title, description;
  final IconData icon;
  final Color accent;
}

class _OnboardingPageContent extends StatelessWidget {
  const _OnboardingPageContent({required this.data});
  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration with accent glow
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: data.accent.withValues(alpha: 0.08),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: data.illustration,
          ),
          const SizedBox(height: 36),
          // Accent icon above title
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, size: 22, color: data.accent),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _bodyTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
