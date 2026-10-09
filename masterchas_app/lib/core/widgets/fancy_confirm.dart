import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/home/presentation/home_palette.dart';
import 'motion.dart';

/// Красивое окно подтверждения: появляется с пружинкой, иконка пульсирует.
Future<bool> showFancyConfirm(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final p = HomePalette.of(context);
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dialog',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: p.cardBg,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseRing(
                    color: color,
                    size: 68,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                      ),
                      child: Icon(icon, color: color, size: 30),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 21, fontWeight: FontWeight.w800, color: p.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(fontSize: 14, color: p.muted, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: HoverLift(
                          radius: 14,
                          lift: 2,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              side: BorderSide(color: p.border, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(cancelLabel, style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: p.text)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HoverLift(
                          radius: 14,
                          lift: 2,
                          glowColor: color,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(confirmLabel, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(scale: Tween<double>(begin: 0.85, end: 1).animate(curved), child: child),
      );
    },
  );
  return result == true;
}
