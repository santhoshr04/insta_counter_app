import 'dart:async';

/// Future integration point: HTTP commands to ESP32 on LAN.
///
/// Do not call real hardware yet — methods are no-ops or return mock values.
class Esp32HttpPlaceholder {
  Future<bool> sendFollowerCount(int count) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return true;
  }

  Future<bool> pingDevice(String deviceId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return deviceId.isNotEmpty;
  }
}

/// Future integration point: MQTT topics for live follower stream.
class MqttBridgePlaceholder {
  Stream<int> followerStream() {
    // ignore: close_sinks
    return const Stream<int>.empty();
  }

  Future<void> publishWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
