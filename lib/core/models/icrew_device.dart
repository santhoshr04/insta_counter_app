/// A discovered Icrew ESP32 (provisioning hotspot scan and/or LAN mDNS).
enum IcrewDiscoverySource {
  /// Seen as Wi‑Fi hotspot `IcrewSetup-<code>` (not yet on your LAN).
  provisioningHotspot,

  /// Resolved on LAN via `_icrew._tcp` mDNS (+ optional HTTP ping).
  mdnsLan,
}

class IcrewDevice {
  const IcrewDevice({
    required this.deviceCode,
    required this.displayName,
    required this.signalLabel,
    required this.sources,
    this.provisioningWifiSsid,
    this.preferredLanOrigin,
    this.signalDbm,
  });

  /// Short unique ID (matches firmware / Wi‑Fi suffix).
  final String deviceCode;

  final String displayName;
  final String signalLabel;
  final Set<IcrewDiscoverySource> sources;

  /// Join this network on the phone before sending Wi‑Fi credentials.
  final String? provisioningWifiSsid;

  /// Use for HTTP control when on the same LAN as the device.
  final Uri? preferredLanOrigin;

  final int? signalDbm;

  /// Stable key for list tiles / prefs.
  String get id => deviceCode.toUpperCase();

  IcrewDevice merge(IcrewDevice other) {
    if (deviceCode.toUpperCase() != other.deviceCode.toUpperCase()) {
      return this;
    }
    return IcrewDevice(
      deviceCode: deviceCode.toUpperCase(),
      displayName: displayName,
      signalLabel: other.signalLabel != '—' ? other.signalLabel : signalLabel,
      sources: {...sources, ...other.sources},
      provisioningWifiSsid: provisioningWifiSsid ?? other.provisioningWifiSsid,
      preferredLanOrigin: preferredLanOrigin ?? other.preferredLanOrigin,
      signalDbm: other.signalDbm ?? signalDbm,
    );
  }

  /// SSID pattern from firmware: `IcrewSetup-<CODE>`.
  static String? parseCodeFromSsid(String ssid) {
    const prefix = 'IcrewSetup-';
    if (!ssid.startsWith(prefix)) return null;
    final tail = ssid.substring(prefix.length).trim();
    if (tail.isEmpty) return null;
    return tail.toUpperCase();
  }
}
