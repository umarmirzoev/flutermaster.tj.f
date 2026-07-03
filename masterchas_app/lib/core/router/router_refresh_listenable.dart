import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] to re-run [GoRouter.redirect] when app state changes.
class RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}
