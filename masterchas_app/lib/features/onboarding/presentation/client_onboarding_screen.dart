import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_illustrations.dart';

/// Green accent from onboarding reference.
const _onboardingGreen = Color(0xFF57B55E);

const _bodyTextColor = Color(0xFF6B7280);
const _inactiveDotColor = Color(0xFFD1D5DB);

class ClientOnboardingScreen extends StatefulWidget {
  const ClientOnboardingScreen({super.key});

  @override
  State<ClientOnboardingScreen> createState() => _ClientOnboardingScreenState();
}

class _ClientOnboardingScreenState extends State<ClientOnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static final _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      illustration: OnboardingIllustrations.nearbyMaster(),
      title: 'Мастер рядом с вами',
      description:
          'Найдите нужного мастера через поиск — система подберёт подходящие анкеты. С помощью фильтров вы сможете выбрать мастеров в вашем городе и районе',
    ),
    _OnboardingPageData(
      illustration: OnboardingIllustrations.ratingReviews(),
      title: 'Рейтинг и отзывы',
      description:
          'Оценивайте работу специалистов и знакомьтесь с отзывами других клиентов. Чем больше положительных оценок, тем выше рейтинг специалиста',
    ),
    _OnboardingPageData(
      illustration: OnboardingIllustrations.serviceRequest(),
      title: 'Оформите заявку на услугу',
      description:
          'Оставьте заявку, и в ближайшие минуты специалисты сами свяжутся с вами и предложат свои услуги',
    ),
    _OnboardingPageData(
      illustration: OnboardingIllustrations.compareCost(),
      title: 'Сопоставляйте стоимость',
      description:
          'Просматривайте стоимость услуг и выбирайте наиболее подходящее предложение. Обязательно учитывайте рейтинг специалиста при выборе',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
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
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Text(
              'Как это работает ?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                height: 1.2,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageContent(data: page);
                },
              ),
            ),
            _PageIndicator(
              count: _pages.length,
              currentIndex: _currentPage,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _onActionPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: _onboardingGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Начать' : 'Пропустить',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
  });

  final Widget illustration;
  final String title;
  final String description;
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
          data.illustration,
          const SizedBox(height: 36),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: _bodyTextColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _onboardingGreen : _inactiveDotColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
