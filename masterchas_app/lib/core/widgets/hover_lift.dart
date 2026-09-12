import 'package:flutter/material.dart';

/// A tiny reusable hover wrapper used across the admin and superadmin
/// dashboards to add a subtle, non-intrusive hover animation (lift / tint /
/// scale) to cards, rows, nav items and buttons. Purely presentational —
/// it never touches data-fetching, providers, or navigation logic.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.enabled = true,
  });

  /// Called on every build with the current hover state.
  final Widget Function(BuildContext context, bool hovering) builder;
  final MouseCursor cursor;
  final bool enabled;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovering = false;

  void _setHover(bool value) {
    if (_hovering == value) return;
    setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? widget.cursor : MouseCursor.defer,
      onEnter: widget.enabled ? (_) => _setHover(true) : null,
      onExit: widget.enabled ? (_) => _setHover(false) : null,
      child: widget.builder(context, widget.enabled && _hovering),
    );
  }
}
