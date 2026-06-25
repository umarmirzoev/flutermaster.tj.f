/// Temporary switches for which parts of the app flow are active.
class AppFlowConfig {
  AppFlowConfig._();

  /// When `true`, splash can navigate forward after the animation.
  static const bool postSplashFlowEnabled = true;

  /// When `true`, splash goes directly to home instead of role selection.
  static const bool splashGoesToHome = true;

  /// When `false`, home is available without signing in.
  static const bool requireAuthForHome = false;
}
