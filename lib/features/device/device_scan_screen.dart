import 'package:flutter/material.dart';
import 'package:insta_counter_app/core/mock/mock_devices.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/features/device/device_setup_screen.dart';
import 'package:insta_counter_app/widgets/device_card.dart';
import 'package:insta_counter_app/widgets/loading_shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  bool _scanning = false;
  bool _hasResults = false;

  Future<void> _runScan() async {
    setState(() {
      _scanning = true;
      _hasResults = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _hasResults = true;
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
            'Scan nearby ESP32 displays (mock). Future builds will use BLE / mDNS.',
            style: GoogleFonts.dmSans(
              color: Colors.white54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
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
                      ? ListView.separated(
                          key: const ValueKey('results'),
                          itemCount: MockDevice.all.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final d = MockDevice.all[i];
                            return DeviceCard(
                              device: d,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        DeviceSetupScreen(device: d),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : Center(
                          key: const ValueKey('empty'),
                          child: Text(
                            'Tap Scan Devices to discover mock hardware.',
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
