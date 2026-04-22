/// App-wide constants for layout, limits, and future hardware hooks.
abstract final class AppConstants {
  static const String appName = 'InstaCounter Pro';

  /// Slider range for manual follower count (mock).
  static const double countSliderMin = 0;
  static const double countSliderMax = 250000;

  /// Default count shown on first launch (split-flap “live” feel).
  static const double defaultFollowerCount = 10607;

  static const Duration splashDuration = Duration(milliseconds: 2200);
}
