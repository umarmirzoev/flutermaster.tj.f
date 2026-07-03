import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeTabProvider = NotifierProvider<HomeTabNotifier, int>(HomeTabNotifier.new);

class HomeTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void openProfile() => state = 3;
}
