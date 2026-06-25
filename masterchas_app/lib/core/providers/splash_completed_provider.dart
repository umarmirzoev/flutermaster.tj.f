import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashCompletedProvider = NotifierProvider<SplashCompletedNotifier, bool>(
  SplashCompletedNotifier.new,
);

class SplashCompletedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}
