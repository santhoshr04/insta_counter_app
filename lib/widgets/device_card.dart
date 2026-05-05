import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insta_counter_app/core/models/icrew_device.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    this.connected = false,
  });

  final IcrewDevice device;
  final VoidCallback onTap;
  final bool connected;

  String _sourceLine() {
    final parts = <String>[];
    if (device.sources.contains(IcrewDiscoverySource.provisioningHotspot)) {
      parts.add('Hotspot');
    }
    if (device.sources.contains(IcrewDiscoverySource.mdnsLan)) {
      parts.add('LAN');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.35),
                      AppTheme.accentSecondary.withValues(alpha: 0.25),
                    ],
                  ),
                ),
                child: const Icon(Icons.memory_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.displayName,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code ${device.deviceCode} · ${_sourceLine()} · ${device.signalLabel}',
                      style: GoogleFonts.dmSans(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    if (device.provisioningWifiSsid != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Join: ${device.provisioningWifiSsid}',
                        style: GoogleFonts.dmSans(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (connected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Live',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentSecondary,
                    ),
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
