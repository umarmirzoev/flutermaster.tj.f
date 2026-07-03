import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../home/presentation/home_palette.dart';

/// Wraps sub-pages in the same 390px mobile shell used across the app.
class ProfileShell extends StatelessWidget {
  const ProfileShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return ColoredBox(
      color: p.pageBg,
      child: child,
    );
  }
}

class ProfileSubPage extends StatelessWidget {
  const ProfileSubPage({super.key, required this.title, required this.body, this.floatingActionButton});

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final p = HomePalette.of(context);
    return ProfileShell(
      child: Scaffold(
        backgroundColor: p.pageBg,
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 10),
                decoration: BoxDecoration(
                  color: p.cardBg,
                  border: Border(bottom: BorderSide(color: p.border)),
                ),
                child: Row(
                  children: [
                    Material(
                      color: p.pageBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.border)),
                          child: Icon(LucideIcons.arrow_left, size: 17, color: p.text),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: p.text),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

Widget profileField({
  required HomePalette p,
  required String label,
  required TextEditingController controller,
  TextInputType? keyboard,
  int maxLines = 1,
  int? maxLength,
  List<TextInputFormatter>? formatters,
  bool obscure = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        maxLength: maxLength,
        obscureText: obscure,
        inputFormatters: formatters,
        style: GoogleFonts.inter(fontSize: 14, color: p.text),
        decoration: InputDecoration(
          filled: true,
          fillColor: p.cardBg,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: brandGreen, width: 1.5)),
        ),
      ),
    ],
  );
}
