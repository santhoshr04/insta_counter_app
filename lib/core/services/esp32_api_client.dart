import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP client for the Icrew ESP32 firmware (provision AP + STA command API).
class Esp32ApiClient {
  const Esp32ApiClient();

  /// Normalizes host input (`192.168.4.1`, `http://icrew.local/`) → [Uri].
  Uri normalizeBaseUri(String input) {
    var s = input.trim();
    if (s.isEmpty) {
      throw FormatException('Base URL cannot be empty');
    }
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    final uri = Uri.parse(s);
    if (uri.host.isEmpty) {
      throw FormatException('Invalid base URL');
    }
    return Uri(
      scheme: uri.scheme.isEmpty ? 'http' : uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    );
  }

  Uri _origin(Uri deviceBaseUri) =>
      Uri.parse(deviceBaseUri.origin);

  /// Lightweight reachability + [deviceCode] JSON (works in SoftAP and STA).
  Future<Esp32ApiResponse<Map<String, dynamic>>> pingDevice({
    required Uri deviceBaseUri,
  }) async {
    final uri = _origin(deviceBaseUri).replace(path: '/api/ping');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) {
        return Esp32ApiResponse.failure(
            'ping ${res.statusCode}: ${_shortBody(res.body)}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return Esp32ApiResponse.success(data: decoded);
      }
      return Esp32ApiResponse.failure('ping: bad JSON');
    } on Object catch (e) {
      return Esp32ApiResponse.failure('$e');
    }
  }

  /// Joke text is fetched by the ESP32 from the internet; the app only reads it here.
  Future<Esp32ApiResponse<String>> fetchJokeFromDevice({
    required Uri deviceBaseUri,
  }) async {
    final uri = _origin(deviceBaseUri).replace(path: '/api/joke');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) {
        return Esp32ApiResponse.failure(
            'joke ${res.statusCode}: ${_shortBody(res.body)}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final ok = decoded['ok'] == true;
        final joke = decoded['joke'];
        if (ok && joke is String && joke.isNotEmpty) {
          return Esp32ApiResponse.success(data: joke);
        }
      }
      return Esp32ApiResponse.failure('unexpected joke response');
    } on Object catch (e) {
      return Esp32ApiResponse.failure('$e');
    }
  }

  /// SoftAP provisioning: `POST /api/wifi` (form fields `ssid`, `password`).
  Future<Esp32ApiResponse<void>> provisionWifi({
    required Uri deviceBaseUri,
    required String ssid,
    required String password,
  }) async {
    final uri = _origin(deviceBaseUri).replace(path: '/api/wifi');
    try {
      final res = await http
          .post(
            uri,
            body: <String, String>{
              'ssid': ssid,
              'password': password,
            },
          )
          .timeout(const Duration(seconds: 45));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return Esp32ApiResponse<void>.success();
      }
      return Esp32ApiResponse.failure(
          'Wi‑Fi POST failed (${res.statusCode}): ${_shortBody(res.body)}');
    } on Object catch (e) {
      return Esp32ApiResponse.failure('$e');
    }
  }

  /// Same commands as UART `help` list.
  Future<Esp32ApiResponse<void>> sendCommand({
    required Uri deviceBaseUri,
    required String cmd,
  }) async {
    final uri = _origin(deviceBaseUri).replace(
      path: '/api/command',
      queryParameters: <String, String>{'cmd': cmd},
    );
    try {
      final res =
          await http.post(uri).timeout(const Duration(seconds: 18));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return Esp32ApiResponse<void>.success();
      }
      return Esp32ApiResponse.failure(
          'command failed (${res.statusCode}): ${_shortBody(res.body)}');
    } on Object catch (e) {
      return Esp32ApiResponse.failure('$e');
    }
  }

  Future<Esp32ApiResponse<Map<String, dynamic>>> fetchStatus({
    required Uri deviceBaseUri,
  }) async {
    final uri = _origin(deviceBaseUri).replace(path: '/api/status');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        return Esp32ApiResponse.failure(
            'status ${res.statusCode}: ${_shortBody(res.body)}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return Esp32ApiResponse.success(data: decoded);
      }
      return Esp32ApiResponse.failure('unexpected JSON shape');
    } on Object catch (e) {
      return Esp32ApiResponse.failure('$e');
    }
  }

  Future<Esp32ApiResponse<void>> factoryReset({
    required Uri deviceBaseUri,
  }) async {
    final uri = _origin(deviceBaseUri).replace(path: '/api/factory');
    try {
      final res =
          await http.post(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return Esp32ApiResponse<void>.success();
      }
      return Esp32ApiResponse.failure(
          'factory reset failed (${res.statusCode}): ${_shortBody(res.body)}');
    } on Object catch (e) {
      return Esp32ApiResponse.failure('$e');
    }
  }

  String _shortBody(String b) =>
      b.length > 140 ? '${b.substring(0, 140)}…' : b;
}

class Esp32ApiResponse<T> {
  Esp32ApiResponse._({required this.success, this.data, this.errorMessage});

  factory Esp32ApiResponse.success({T? data}) =>
      Esp32ApiResponse<T>._(success: true, data: data);

  factory Esp32ApiResponse.failure(String message) =>
      Esp32ApiResponse<T>._(success: false, errorMessage: message);

  final bool success;
  final T? data;
  final String? errorMessage;
}
