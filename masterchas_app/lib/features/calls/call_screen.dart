import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/motion.dart';
import 'call_controller.dart';

const _green = Color(0xFF57B55E);
const _red = Color(0xFFEF4444);

/// Полноэкранный экран звонка: исходящий, входящий и разговор.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  late final CallController _call = ref.read(callControllerProvider);
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _call.addListener(_onChange);
  }

  @override
  void dispose() {
    _call.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    if (_call.phase == CallPhase.idle && !_closing) {
      _closing = true;
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  Future<void> _accept() async {
    final error = await _call.accept();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, style: GoogleFonts.manrope()), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _call;
    final initial = c.peerName.trim().isNotEmpty ? c.peerName.trim()[0].toUpperCase() : '?';
    final ringing = c.phase == CallPhase.outgoing || c.phase == CallPhase.incoming;
    final ended = c.phase == CallPhase.ended || c.phase == CallPhase.idle;

    return PopScope(
      canPop: ended,
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1D243D), Color(0xFF14532D)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // В браузере звук собеседника играет через этот (невидимый) рендерер.
                SizedBox(width: 1, height: 1, child: RTCVideoView(c.remoteRenderer)),
                Positioned(
                  top: -60,
                  right: -40,
                  child: FloatY(
                    amplitude: 10,
                    period: const Duration(milliseconds: 5000),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _green.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const SizedBox(height: 18),
                    Reveal(
                      offsetY: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.lock, size: 13, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              'Звонок зашифрован',
                              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    Reveal(
                      child: PulseRing(
                        color: ringing ? _green : Colors.transparent,
                        size: 132,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6DD674), Color(0xFF2E9E4F)],
                            ),
                            boxShadow: [
                              BoxShadow(color: _green.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: GoogleFonts.manrope(fontSize: 54, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Reveal(
                      delay: const Duration(milliseconds: 100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          c.peerName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        c.statusText,
                        key: ValueKey(c.statusText),
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.phase == CallPhase.active ? const Color(0xFF86EFAC) : Colors.white70,
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    if (c.phase == CallPhase.incoming)
                      Reveal(
                        offsetY: 30,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RoundAction(
                              icon: LucideIcons.phone_off,
                              color: _red,
                              label: 'Отклонить',
                              onTap: () => c.decline(),
                            ),
                            _RoundAction(
                              icon: LucideIcons.phone,
                              color: _green,
                              label: 'Ответить',
                              pulse: true,
                              onTap: _accept,
                            ),
                          ],
                        ),
                      )
                    else if (!ended)
                      Reveal(
                        offsetY: 30,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RoundAction(
                              icon: c.muted ? LucideIcons.mic_off : LucideIcons.mic,
                              color: c.muted ? Colors.white : Colors.white.withValues(alpha: 0.14),
                              iconColor: c.muted ? const Color(0xFF111827) : Colors.white,
                              label: c.muted ? 'Микрофон выкл.' : 'Микрофон',
                              onTap: c.toggleMute,
                            ),
                            _RoundAction(
                              icon: LucideIcons.phone_off,
                              color: _red,
                              label: 'Завершить',
                              big: true,
                              onTap: () => c.hangUp(),
                            ),
                            _RoundAction(
                              icon: c.speakerOn ? LucideIcons.volume_2 : LucideIcons.volume_1,
                              color: c.speakerOn ? Colors.white : Colors.white.withValues(alpha: 0.14),
                              iconColor: c.speakerOn ? const Color(0xFF111827) : Colors.white,
                              label: 'Динамик',
                              onTap: c.toggleSpeaker,
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: 96),
                    const SizedBox(height: 48),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatefulWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
    this.big = false,
    this.pulse = false,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool big;
  final bool pulse;

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.big ? 76.0 : 64.0;
    Widget button = AnimatedScale(
      scale: _pressed ? 0.9 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Icon(widget.icon, color: widget.iconColor, size: widget.big ? 30 : 26),
      ),
    );
    if (widget.pulse) {
      button = PulseRing(color: widget.color, size: size, child: button);
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: HoverLift(
        radius: size / 2,
        scale: 1.08,
        glowColor: widget.color,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button,
            const SizedBox(height: 10),
            Text(
              widget.label,
              style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
