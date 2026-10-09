import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/signalr_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/motion.dart';
import '../auth/providers/auth_provider.dart';
import 'call_controller.dart';
import 'call_screen.dart';

/// Слушает входящие звонки на любом экране приложения и открывает CallScreen.
/// Оборачивает всё приложение (MaterialApp.router → builder).
class CallHost extends ConsumerStatefulWidget {
  const CallHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CallHost> createState() => _CallHostState();
}

class _CallHostState extends ConsumerState<CallHost> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final call = ref.read(callControllerProvider);
    call.onIncoming = _showCallScreen;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAttach());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Вернулись в приложение — переподключаемся, чтобы не пропустить звонок.
    if (state == AppLifecycleState.resumed) _maybeAttach();
  }

  void _maybeAttach() {
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && !auth.isGuest) {
      ref.read(callControllerProvider).attach();
    }
  }

  void _showCallScreen() {
    final nav = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentState;
    nav?.push(SmoothRoute<void>(builder: (_) => const CallScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // После входа в аккаунт подключаемся к звонкам.
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated && !next.isGuest && previous?.isAuthenticated != true) {
        ref.read(callControllerProvider).attach();
      }
      // Вышли из аккаунта — кладём трубку и отключаемся, чтобы звонки старого аккаунта не приходили.
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        final call = ref.read(callControllerProvider);
        if (call.busy) call.hangUp();
        ref.read(signalRServiceProvider).disconnect();
      }
    });
    return widget.child;
  }
}
