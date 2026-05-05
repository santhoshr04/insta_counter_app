import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insta_counter_app/core/models/icrew_device.dart';
import 'package:insta_counter_app/core/services/icrew_discovery_service.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/features/device/device_manage_screen.dart';
import 'package:insta_counter_app/widgets/device_card.dart';
import 'package:insta_counter_app/widgets/loading_shimmer.dart';
import 'package:wifi_scan/wifi_scan.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  final _discovery = const IcrewDiscoveryService();
  bool _scanning = false;
  bool _hasResults = false;
  List<IcrewDevice> _devices = const [];
  String? _wifiHint;

  String? _wifiScanHintFromEnum(CanStartScan c) {
    switch (c) {
      case CanStartScan.yes:
        return null;
      case CanStartScan.notSupported:
        return 'Wi‑Fi scan is not supported on this device.';
      case CanStartScan.noLocationPermissionRequired:
      case CanStartScan.noLocationPermissionDenied:
      case CanStartScan.noLocationPermissionUpgradeAccuracy:
        return 'Allow location access so Android can list nearby Wi‑Fi (needed to see IcrewSetup-… hotspots).';
      case CanStartScan.noLocationServiceDisabled:
        return 'Turn on Location services to scan for IcrewSetup hotspots.';
      case CanStartScan.failed:
        return 'Wi‑Fi scan could not start. Try again in a few seconds.';
    }
  }

  Future<void> _runScan() async {
    setState(() {
      _scanning = true;
      _hasResults = false;
      _wifiHint = null;
    });

    if (Platform.isAndroid) {
      final can = await WiFiScan.instance.canStartScan(askPermissions: true);
      if (can != CanStartScan.yes) {
        setState(() => _wifiHint = _wifiScanHintFromEnum(can));
      }
    }

    final list = await _discovery.discoverAll();
    if (!mounted) return;

    setState(() {
      _scanning = false;
      _hasResults = true;
      _devices = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Scans for IcrewSetup-XXXX hotspots (Android) and for Icrew boards on your LAN (mDNS). Each board has a unique code in firmware.',
            style: GoogleFonts.dmSans(
              color: Colors.white54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (_wifiHint != null) ...[
            const SizedBox(height: 10),
            Text(
              _wifiHint!,
              style: GoogleFonts.dmSans(
                color: AppTheme.accentSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _scanning ? null : _runScan,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.radar_rounded),
            label: Text(_scanning ? 'Scanning…' : 'Scan Devices'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _scanning
                  ? Column(
                      key: const ValueKey('scanning'),
                      children: const [
                        LoadingShimmer(height: 72, borderRadius: 18),
                        SizedBox(height: 12),
                        LoadingShimmer(height: 72, borderRadius: 18),
                      ],
                    )
                  : _hasResults
                      ? _devices.isEmpty
                          ? Center(
                              key: const ValueKey('empty_results'),
                              child: Text(
                                'No Icrew devices found.\n'
                                '• Power an ESP32 with this firmware (unique hotspot IcrewSetup-…).\n'
                                '• On Android, allow location and try again.\n'
                                '• On LAN, ensure the phone is on the same Wi‑Fi as the display.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white38,
                                  height: 1.45,
                                ),
                              ),
                            )
                          : ListView.separated(
                              key: const ValueKey('results'),
                              itemCount: _devices.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final d = _devices[i];
                                return DeviceCard(
                                  device: d,
                                  onTap: () {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            DeviceManageScreen(device: d),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                      : Center(
                          key: const ValueKey('empty'),
                          child: Text(
                            'Tap Scan Devices to find nearby Icrew hardware.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(color: Colors.white38),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
