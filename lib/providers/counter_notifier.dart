import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:insta_counter_app/core/constants/app_constants.dart';

/// Live update cadence for simulated follower growth.
enum LiveUpdateSpeed {
  slow,
  normal,
  fast,
}

/// Global follower count + simulated live stream (mock).
class CounterNotifier extends ChangeNotifier {
  CounterNotifier() {
    _count = AppConstants.defaultFollowerCount;
    _restartTimer();
  }

  double _count = AppConstants.defaultFollowerCount;
  bool pauseLiveUpdates = false;
  LiveUpdateSpeed speed = LiveUpdateSpeed.normal;

  Timer? _timer;

  double get count => _count;

  Duration get _tick {
    switch (speed) {
      case LiveUpdateSpeed.slow:
        return const Duration(seconds: 4);
      case LiveUpdateSpeed.normal:
        return const Duration(seconds: 2);
      case LiveUpdateSpeed.fast:
        return const Duration(seconds: 1);
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      if (pauseLiveUpdates) return;
      final delta = 1 + Random().nextInt(4);
      _count += delta;
      _count = _count.clamp(
        AppConstants.countSliderMin,
        AppConstants.countSliderMax,
      );
      notifyListeners();
    });
  }

  void setPause(bool value) {
    pauseLiveUpdates = value;
    notifyListeners();
  }

  void setSpeed(LiveUpdateSpeed value) {
    if (speed == value) return;
    speed = value;
    notifyListeners();
    _restartTimer();
  }

  void add(double delta) {
    _count = (_count + delta).clamp(
      AppConstants.countSliderMin,
      AppConstants.countSliderMax,
    );
    notifyListeners();
    HapticFeedback.lightImpact();
  }

  void setCount(double value) {
    _count = value.clamp(
      AppConstants.countSliderMin,
      AppConstants.countSliderMax,
    );
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
