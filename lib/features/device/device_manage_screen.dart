import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insta_counter_app/core/models/icrew_device.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/features/device/device_setup_screen.dart';
import 'package:insta_counter_app/features/device/esp32_control_screen.dart';

/// Entry point after picking a discovered device — Wi‑Fi provisioning or HTTP control.
class DeviceManageScreen extends StatelessWidget {
  const DeviceManageScreen({super.key, required this.device});

  final IcrewDevice device;

  String _provisionSsidLine() {
    final s = device.provisioningWifiSsid;
    if (s != null && s.isNotEmpty) {
      return 'Phone Wi‑Fi must join: $s';
    }
    return 'Hotspot name: IcrewSetup-${device.deviceCode}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.displayName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Hardware',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Device code ${device.deviceCode}. $_provisionSsidLine. '
            'Motor commands and jokes use HTTP on the LAN; jokes are downloaded by the ESP32, not the phone.',
            style: GoogleFonts.dmSans(
              color: Colors.white54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _tile(
            context,
            icon: Icons.wifi_rounded,
            title: 'Wi‑Fi provisioning',
            subtitle:
                'After joining the device hotspot, POST credentials to http://192.168.4.1',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => DeviceSetupScreen(device: device),
                ),
              );
            },
          ),
          _tile(
            context,
            icon: Icons.tune_rounded,
            title: 'Motor & firmware control',
            subtitle: device.preferredLanOrigin != null
                ? 'Suggested: ${device.preferredLanOrigin}'
                : 'Use http://icrew-${device.deviceCode.toLowerCase()}.local or DHCP IP',
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => Esp32ControlScreen(
                    deviceName: device.displayName,
                    pickedDevice: device,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
          child: Icon(icon, color: AppTheme.accent),
        ),
        title: Text(title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.dmSans(
            color: Colors.white54,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
