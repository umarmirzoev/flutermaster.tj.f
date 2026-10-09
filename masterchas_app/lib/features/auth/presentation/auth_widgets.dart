import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/motion.dart';

/// Общие красивые виджеты для экранов входа и регистрации.
const authGreen = Color(0xFF57B55E);
const authTitle = Color(0xFF111827);
const authBody = Color(0xFF6B7280);
const authHint = Color(0xFF9CA3AF);

/// Мягкие плавающие пятна на фоне.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key});

  Widget _blob(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c.withValues(alpha: 0.16), c.withValues(alpha: 0)]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -70,
            child: FloatY(amplitude: 10, period: const Duration(milliseconds: 5200), child: _blob(authGreen, 260)),
          ),
          Positioned(
            top: 260,
            left: -110,
            child: FloatY(amplitude: 8, phase: 0.4, period: const Duration(milliseconds: 6400), child: _blob(const Color(0xFF3B82F6), 200)),
          ),
          Positioned(
            bottom: -90,
            right: -60,
            child: FloatY(amplitude: 9, phase: 0.7, period: const Duration(milliseconds: 5800), child: _blob(const Color(0xFFF59E0B), 220)),
          ),
        ],
      ),
    );
  }
}

/// Большая пульсирующая иконка в шапке экрана.
class AuthHeroIcon extends StatelessWidget {
  const AuthHeroIcon({super.key, required this.icon, this.size = 72});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FloatY(
      amplitude: 4,
      child: PulseRing(
        color: authGreen,
        size: size,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6DD674), Color(0xFF2E9E4F)],
            ),
            boxShadow: [
              BoxShadow(color: authGreen.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8)),
            ],
          ),
          child: Icon(icon, size: size * 0.44, color: Colors.white),
        ),
      ),
    );
  }
}

/// Круглая кнопка «назад» с ховером.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      radius: 14,
      lift: 2,
      scale: 1.08,
      glowColor: authGreen,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: authGreen.withValues(alpha: 0.25)),
            ),
            child: const Icon(LucideIcons.arrow_left, color: authGreen, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Поле ввода со свечением при фокусе.
class AuthGlowField extends StatefulWidget {
  const AuthGlowField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
    this.prefixText,
    this.inputFormatters,
    this.trailing,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;
  final TextInputAction? textInputAction;

  @override
  State<AuthGlowField> createState() => _AuthGlowFieldState();
}

class _AuthGlowFieldState extends State<AuthGlowField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: authGreen.withValues(alpha: _focused ? 0.22 : 0.06),
              blurRadius: _focused ? 24 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: w.controller,
          obscureText: w.obscure,
          keyboardType: w.keyboardType,
          inputFormatters: w.inputFormatters,
          textInputAction: w.textInputAction,
          onChanged: w.onChanged,
          onSubmitted: w.onSubmitted,
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: authTitle),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            labelText: w.label,
            labelStyle: GoogleFonts.manrope(fontSize: 14, color: authHint),
            floatingLabelStyle: GoogleFonts.manrope(fontSize: 13, color: authGreen, fontWeight: FontWeight.w700),
            hintText: w.hint,
            hintStyle: GoogleFonts.manrope(fontSize: 15, color: const Color(0xFFC4C9D0)),
            prefixText: w.prefixText,
            prefixStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: authTitle),
            prefixIcon: AnimatedScale(
              scale: _focused ? 1.1 : 1,
              duration: const Duration(milliseconds: 220),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(left: 10, right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: authGreen.withValues(alpha: _focused ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(w.icon, size: 19, color: authGreen),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: w.onToggleObscure != null
                ? IconButton(
                    onPressed: w.onToggleObscure,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (c, a) => RotationTransition(turns: Tween(begin: 0.75, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: c)),
                      child: Icon(
                        w.obscure ? LucideIcons.eye_off : LucideIcons.eye,
                        key: ValueKey(w.obscure),
                        size: 20,
                        color: _focused ? authGreen : authHint,
                      ),
                    ),
                  )
                : w.trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: authGreen, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Главная зелёная кнопка: блик, ховер, нажатие, загрузка.
class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.loading,
    required this.onTap,
    this.loadingLabel,
  });

  final String label;
  final String? loadingLabel;
  final IconData icon;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !widget.loading;
    final button = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: widget.enabled
                ? const [Color(0xFF4BAF50), Color(0xFF57B55E), Color(0xFF6DD674)]
                : [authGreen.withValues(alpha: 0.32), authGreen.withValues(alpha: 0.28)],
          ),
          boxShadow: widget.enabled
              ? [BoxShadow(color: authGreen.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 7))]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? widget.onTap : null,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Row(
                  key: ValueKey(widget.loading),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.loading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    else
                      Icon(widget.icon, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      widget.loading ? (widget.loadingLabel ?? widget.label) : widget.label,
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!widget.enabled) return button;
    return HoverLift(
      radius: 16,
      scale: 1.02,
      glowColor: authGreen,
      child: ShineSweep(radius: 16, child: button),
    );
  }
}

/// Красная плашка ошибки с «встряской».
class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (c, a) => SizeTransition(sizeFactor: a, child: FadeTransition(opacity: a, child: c)),
      child: message == null
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : TweenAnimationBuilder<double>(
              key: ValueKey(message),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, t, child) {
                final dx = (1 - t) * 10 * ((t * 12).floor().isEven ? 1 : -1);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.circle_alert, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message!,
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Маленький чип-требование (зеленеет, когда выполнено).
class AuthCheckChip extends StatelessWidget {
  const AuthCheckChip({super.key, required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? authGreen.withValues(alpha: 0.12) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ok ? authGreen.withValues(alpha: 0.4) : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
            child: Icon(
              ok ? LucideIcons.circle_check : LucideIcons.circle,
              key: ValueKey(ok),
              size: 14,
              color: ok ? authGreen : authHint,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: ok ? const Color(0xFF2E7D32) : authBody),
          ),
        ],
      ),
    );
  }
}
