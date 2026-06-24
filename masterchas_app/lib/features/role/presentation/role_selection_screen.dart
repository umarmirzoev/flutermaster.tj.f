import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same green as splash screen.
const _clientGreen = Color(0xFF57B55E);

/// Dark navy from role-selection reference.
const _masterNavy = Color(0xFF1C2438);

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _RolePanel(
              backgroundColor: _clientGreen,
              bokehColor: const Color(0xFF6BC472),
              bokehCircles: const [
                _BokehCircle(alignment: Alignment(-0.95, -0.82), size: 220),
                _BokehCircle(alignment: Alignment(0.92, -0.55), size: 180),
                _BokehCircle(alignment: Alignment(-0.75, 0.88), size: 200),
              ],
              icon: const _ClientIcon(),
              title: 'Я клиент',
              onTap: () => context.go('/client/onboarding'),
            ),
          ),
          Expanded(
            child: _RolePanel(
              backgroundColor: _masterNavy,
              bokehColor: const Color(0xFF2A3550),
              bokehCircles: const [
                _BokehCircle(alignment: Alignment(0.9, -0.75), size: 190),
                _BokehCircle(alignment: Alignment(-0.85, 0.55), size: 210),
                _BokehCircle(alignment: Alignment(0.7, 0.92), size: 240),
              ],
              icon: const _MasterIcon(),
              title: 'Я мастер',
              onTap: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BokehCircle {
  const _BokehCircle({
    required this.alignment,
    required this.size,
  });

  final Alignment alignment;
  final double size;
}

class _RolePanel extends StatelessWidget {
  const _RolePanel({
    required this.backgroundColor,
    required this.bokehColor,
    required this.bokehCircles,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Color backgroundColor;
  final Color bokehColor;
  final List<_BokehCircle> bokehCircles;
  final Widget icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ...bokehCircles.map(
              (circle) => Align(
                alignment: circle.alignment,
                child: _SoftCircle(
                  diameter: circle.size,
                  color: bokehColor.withValues(alpha: 0.55),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconRing(child: icon),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _ArrowButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _IconRing extends StatelessWidget {
  const _IconRing({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: const Icon(
        LucideIcons.arrow_right,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _ClientIcon extends StatelessWidget {
  const _ClientIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            LucideIcons.user,
            color: Colors.white,
            size: 52,
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Icon(
              LucideIcons.search,
              color: Colors.white.withValues(alpha: 0.95),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasterIcon extends StatelessWidget {
  const _MasterIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.55,
            child: const Icon(
              LucideIcons.hammer,
              color: Colors.white,
              size: 50,
            ),
          ),
          Transform.rotate(
            angle: 0.55,
            child: const Icon(
              LucideIcons.wrench,
              color: Colors.white,
              size: 46,
            ),
          ),
        ],
      ),
    );
  }
}
