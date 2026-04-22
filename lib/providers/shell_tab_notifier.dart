import 'package:flutter/foundation.dart';

/// Lets deep links / settings jump between bottom-nav sections.
class ShellTabNotifier extends ChangeNotifier {
  int index = 0;

  void setTab(int value) {
    if (value == index || value < 0 || value > 3) return;
    index = value;
    notifyListeners();
  }
}
