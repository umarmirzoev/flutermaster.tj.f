import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// Green accent used across onboarding illustrations.
const onboardingIllustrationGreen = Color(0xFF57B55E);

/// Sharp vector illustrations for each onboarding step.
class OnboardingIllustrations {
  OnboardingIllustrations._();

  static Widget nearbyMaster() => const _IllustrationFrame(
        child: _IconCluster(
          main: Icon(
            LucideIcons.map_pin,
            size: 88,
            color: onboardingIllustrationGreen,
          ),
          accents: [
            _AccentIcon(
              alignment: Alignment(-0.92, -0.55),
              icon: LucideIcons.wrench,
              size: 34,
            ),
            _AccentIcon(
              alignment: Alignment(0.95, 0.45),
              icon: LucideIcons.search,
              size: 40,
            ),
            _AccentIcon(
              alignment: Alignment(-0.55, 0.82),
              icon: LucideIcons.hammer,
              size: 30,
            ),
          ],
        ),
      );

  static Widget ratingReviews() => const _IllustrationFrame(
        child: _IconCluster(
          main: Icon(
            LucideIcons.star,
            size: 88,
            color: onboardingIllustrationGreen,
          ),
          accents: [
            _AccentIcon(
              alignment: Alignment(-0.95, 0.35),
              icon: LucideIcons.user,
              size: 38,
            ),
            _AccentIcon(
              alignment: Alignment(0.1, 0.88),
              icon: LucideIcons.chart_column_increasing,
              size: 42,
            ),
            _AccentIcon(
              alignment: Alignment(0.95, -0.15),
              icon: LucideIcons.trending_up,
              size: 38,
            ),
          ],
        ),
      );

  static Widget serviceRequest() => const _IllustrationFrame(
        child: _IconCluster(
          main: Icon(
            LucideIcons.clipboard_check,
            size: 86,
            color: onboardingIllustrationGreen,
          ),
          accents: [
            _AccentIcon(
              alignment: Alignment(-0.98, -0.1),
              icon: LucideIcons.user,
              size: 40,
            ),
            _AccentIcon(
              alignment: Alignment(0.98, 0.55),
              icon: LucideIcons.hard_hat,
              size: 40,
            ),
            _AccentIcon(
              alignment: Alignment(0.05, -0.88),
              icon: LucideIcons.arrow_left_right,
              size: 34,
            ),
          ],
        ),
      );

  static Widget compareCost() => _IllustrationFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.user,
                  size: 36,
                  color: onboardingIllustrationGreen,
                ),
                SizedBox(width: 10),
                Icon(
                  LucideIcons.user,
                  size: 42,
                  color: onboardingIllustrationGreen,
                ),
                SizedBox(width: 10),
                Icon(
                  LucideIcons.user,
                  size: 36,
                  color: onboardingIllustrationGreen,
                ),
              ],
            ),
            SizedBox(height: 22),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.heart,
                  size: 48,
                  color: onboardingIllustrationGreen,
                ),
                SizedBox(width: 36),
                Icon(
                  LucideIcons.circle_dollar_sign,
                  size: 52,
                  color: onboardingIllustrationGreen,
                ),
              ],
            ),
          ],
        ),
      );
}

class _IllustrationFrame extends StatelessWidget {
  const _IllustrationFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onboardingIllustrationGreen.withValues(alpha: 0.1),
            ),
          ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: onboardingIllustrationGreen.withValues(alpha: 0.18),
                width: 1.5,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _IconCluster extends StatelessWidget {
  const _IconCluster({
    required this.main,
    required this.accents,
  });

  final Widget main;
  final List<_AccentIcon> accents;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          main,
          ...accents,
        ],
      ),
    );
  }
}

class _AccentIcon extends StatelessWidget {
  const _AccentIcon({
    required this.alignment,
    required this.icon,
    required this.size,
  });

  final Alignment alignment;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Icon(
        icon,
        size: size,
        color: onboardingIllustrationGreen,
      ),
    );
  }
}
