import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/home_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_design.dart';
import '../../home/presentation/home_palette.dart';
import '../../masters/data/masters_data.dart';

class MasterStory {
  const MasterStory({
    required this.masterName,
    required this.profession,
    required this.avatar,
    required this.slides,
    this.viewed = false,
  });

  final String masterName;
  final String profession;
  final String avatar;
  final List<StorySlide> slides;
  final bool viewed;
}

class StorySlide {
  const StorySlide({required this.image, required this.caption});
  final String image;
  final String caption;
}

List<MasterStory> localizedStories(HomeStrings s, AppLocale locale) => [
      MasterStory(
        masterName: 'Алишер М.',
        profession: localizedCategory('Электрика', locale),
        avatar: 'assets/images/master_1.png',
        slides: [
          StorySlide(image: 'assets/images/master_1.png', caption: s.storyCaptionWiring),
          StorySlide(image: 'assets/images/master_2.png', caption: s.storyCaptionSmartHome),
        ],
      ),
      MasterStory(
        masterName: 'Фаррух Р.',
        profession: localizedCategory('Сантехника', locale),
        avatar: 'assets/images/master_2.png',
        slides: [
          StorySlide(image: 'assets/images/master_2.png', caption: s.storyCaptionHeating),
        ],
      ),
      MasterStory(
        masterName: 'Джамшед К.',
        profession: localizedCategory('Отделка', locale),
        avatar: 'assets/images/master_3.png',
        slides: [
          StorySlide(image: 'assets/images/master_3.png', caption: s.storyCaptionTurnkey),
          StorySlide(image: 'assets/images/master_1.png', caption: s.storyCaptionTile),
        ],
      ),
      MasterStory(
        masterName: 'Бахтиёр С.',
        profession: localizedCategory('Мебель и двери', locale),
        avatar: 'assets/images/master_1.png',
        slides: [
          StorySlide(image: 'assets/images/master_2.png', caption: s.storyCaptionKitchen),
        ],
        viewed: true,
      ),
    ];

/// Horizontal stories reel for the home feed.
class StoriesReel extends ConsumerWidget {
  const StoriesReel({super.key, required this.p});

  final HomePalette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = HomeStrings.of(locale);
    final stories = localizedStories(s, locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Row(
            children: [
              const Icon(LucideIcons.clapperboard, size: 18, color: AppDesign.brand),
              const SizedBox(width: 6),
              Text(
                s.mastersWorksTitle,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: p.text),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _StoryBubble(
              story: stories[i],
              onTap: () => _openStory(context, stories, i),
            ),
          ),
        ),
      ],
    );
  }

  void _openStory(BuildContext context, List<MasterStory> stories, int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => StoryViewer(stories: stories, initialIndex: index),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.story, required this.onTap});

  final MasterStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story.viewed
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6DD674), Color(0xFF57B55E), Color(0xFFF59E0B)],
                      ),
                color: story.viewed ? Colors.grey.withValues(alpha: 0.3) : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(story.avatar, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.masterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1C1C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen story viewer with auto-advancing progress bars.
class StoryViewer extends ConsumerStatefulWidget {
  const StoryViewer({super.key, required this.stories, required this.initialIndex});

  final List<MasterStory> stories;
  final int initialIndex;

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer> with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  late int _storyIndex;
  int _slideIndex = 0;

  MasterStory get _story => widget.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _storyIndex = widget.initialIndex;
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _next() {
    if (_slideIndex < _story.slides.length - 1) {
      setState(() => _slideIndex++);
      _progress.forward(from: 0);
    } else if (_storyIndex < widget.stories.length - 1) {
      setState(() {
        _storyIndex++;
        _slideIndex = 0;
      });
      _progress.forward(from: 0);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_slideIndex > 0) {
      setState(() => _slideIndex--);
      _progress.forward(from: 0);
    } else if (_storyIndex > 0) {
      setState(() {
        _storyIndex--;
        _slideIndex = 0;
      });
      _progress.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = HomeStrings.of(ref.watch(localeProvider));
    final slide = _story.slides[_slideIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final w = MediaQuery.sizeOf(context).width;
          if (details.globalPosition.dx < w / 3) {
            _prev();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _progress.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(slide.image, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0, 0.2, 0.7, 1],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: List.generate(_story.slides.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: SizedBox(
                                height: 3,
                                child: AnimatedBuilder(
                                  animation: _progress,
                                  builder: (context, _) {
                                    double value;
                                    if (i < _slideIndex) {
                                      value = 1;
                                    } else if (i == _slideIndex) {
                                      value = _progress.value;
                                    } else {
                                      value = 0;
                                    }
                                    return LinearProgressIndicator(
                                      value: value,
                                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(child: Image.asset(_story.avatar, fit: BoxFit.cover)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _story.masterName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _story.profession,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(LucideIcons.x, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.caption,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GradientButton(
                                label: s.storyOrderBtn,
                                icon: LucideIcons.calendar_check,
                                height: 48,
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(LucideIcons.heart, color: Colors.white, size: 22),
                            ),
                          ],
                        ),
                      ],
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
}
