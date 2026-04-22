import 'package:flutter/foundation.dart';

/// Toggles between premium dark and graphite variant from Profile.
class ThemeVariantNotifier extends ChangeNotifier {
  bool useGraphite = false;

  void toggle() {
    useGraphite = !useGraphite;
    notifyListeners();
  }
}
