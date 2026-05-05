import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insta_counter_app/core/models/icrew_device.dart';
import 'package:insta_counter_app/core/services/esp32_api_client.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/providers/device_hub_notifier.dart';
import 'package:provider/provider.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key, required this.device});

  final IcrewDevice device;

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final _api = const Esp32ApiClient();
  final _host = TextEditingController(text: 'http://192.168.4.1');
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  bool _sending = false;

  String get _expectedHotspotSsid =>
      widget.device.provisioningWifiSsid ??
      'IcrewSetup-${widget.device.deviceCode}';

  String get _postProvisionOrigin {
    final c = widget.device.deviceCode.toLowerCase();
    return 'http://icrew-$c.local';
  }

  @override
  void dispose() {
    _host.dispose();
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final hub = context.read<DeviceHubNotifier>();
    late final Uri origin;
    try {
      origin = _api.normalizeBaseUri(_host.text);
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }

    final ssid = _ssid.text.trim();
    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter the Wi‑Fi network name.',
            style: GoogleFonts.dmSans(),
          ),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final ping = await _api.pingDevice(deviceBaseUri: origin);
      if (!ping.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot reach the device at $origin. Join Wi‑Fi "$_expectedHotspotSsid" '
              'on this phone first, then try again. (${ping.errorMessage ?? "ping failed"})',
              style: GoogleFonts.dmSans(),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }

      final res = await _api.provisionWifi(
        deviceBaseUri: origin,
        ssid: ssid,
        password: _password.text,
      );
      if (!mounted) return;

      if (res.success) {
        await hub.setOrigin(Uri.parse(_postProvisionOrigin));
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.device.displayName} saved Wi‑Fi and is rebooting. '
              'Reconnect your phone to the same home Wi‑Fi, then open Motor control — '
              'try $_postProvisionOrigin or the IP shown on the serial log.',
              style: GoogleFonts.dmSans(),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.errorMessage ?? 'Provision failed',
              style: GoogleFonts.dmSans(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi‑Fi provisioning'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.device.displayName,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '1) On the phone, join Wi‑Fi "$_expectedHotspotSsid".\n'
              '2) Leave device URL as http://192.168.4.1 (gateway of the ESP32 hotspot).\n'
              '3) Enter your home Wi‑Fi SSID and password, then send.\n'
              'If ping still fails, the phone is not on that hotspot.',
              style: GoogleFonts.dmSans(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _host,
              decoration: InputDecoration(
                labelText: 'Device URL while on device hotspot',
                labelStyle: GoogleFonts.dmSans(color: Colors.white60),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.outline),
                ),
              ),
              style: GoogleFonts.dmSans(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ssid,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Home Wi‑Fi name (SSID)',
                labelStyle: GoogleFonts.dmSans(color: Colors.white60),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.outline),
                ),
              ),
              style: GoogleFonts.dmSans(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Home Wi‑Fi password',
                labelStyle: GoogleFonts.dmSans(color: Colors.white60),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.outline),
                ),
              ),
              style: GoogleFonts.dmSans(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.accentSecondary,
                foregroundColor: Colors.black,
              ),
              child: _sending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Send to ESP32',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
