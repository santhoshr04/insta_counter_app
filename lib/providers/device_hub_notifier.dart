import 'package:flutter/foundation.dart';
import 'package:insta_counter_app/core/services/esp32_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved device HTTP origin for LAN / provisioning calls.
class DeviceHubNotifier extends ChangeNotifier {
  DeviceHubNotifier() {
    Future<void>(() async => load());
  }

  static const _prefsKey = 'esp32_device_origin';

  Uri _origin = Uri.parse('http://icrew.local');

  Uri get origin => _origin;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_prefsKey);
    if (s != null && s.trim().isNotEmpty) {
      try {
        _origin = const Esp32ApiClient().normalizeBaseUri(s.trim());
        notifyListeners();
      } catch (_) {
        /* keep default */
      }
    }
  }

  Future<void> setOriginFromString(String input) async {
    final normalized = const Esp32ApiClient().normalizeBaseUri(input);
    _origin = normalized;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, _origin.toString());
  }

  Future<void> setOrigin(Uri uri) async {
    _origin = uri;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, _origin.toString());
  }
}
