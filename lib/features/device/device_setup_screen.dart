import 'package:flutter/material.dart';
import 'package:insta_counter_app/core/mock/mock_devices.dart';
import 'package:insta_counter_app/core/services/hardware_bridge_placeholder.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key, required this.device});

  final MockDevice device;

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final _ssid = TextEditingController(text: 'CafeGuest');
  final _password = TextEditingController();
  final _mqtt = MqttBridgePlaceholder();
  bool _sending = false;

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await _mqtt.publishWifiCredentials(
      ssid: _ssid.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Credentials queued for ${widget.device.name} (mock).',
          style: GoogleFonts.dmSans(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.device.name,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Provision Wi-Fi for the display. Values are not sent to real hardware yet.',
              style: GoogleFonts.dmSans(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _ssid,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'WiFi Name (SSID)',
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
                labelText: 'Password',
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
                      'Send to Device',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
