import 'dart:io';

import 'package:insta_counter_app/core/models/icrew_device.dart';
import 'package:insta_counter_app/core/services/esp32_api_client.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:wifi_scan/wifi_scan.dart';

/// Discovers Icrew hardware: Wi‑Fi scan for `IcrewSetup-*` APs and LAN `_icrew._tcp` mDNS.
class IcrewDiscoveryService {
  const IcrewDiscoveryService();

  static const _icrewPtrDomain = '_icrew._tcp.local';

  Future<List<IcrewDevice>> discoverAll() async {
    final results = await Future.wait([
      discoverProvisioningHotspots(),
      discoverLanMdns(),
    ]);
    return _mergeByCode([...results[0], ...results[1]]);
  }

  Future<List<IcrewDevice>> discoverProvisioningHotspots() async {
    if (!Platform.isAndroid) {
      return const [];
    }

    final canStart =
        await WiFiScan.instance.canStartScan(askPermissions: true);
    if (canStart != CanStartScan.yes) {
      return const [];
    }

    await WiFiScan.instance.startScan();
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final canGet =
        await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if (canGet != CanGetScannedResults.yes) {
      return const [];
    }

    final nets = await WiFiScan.instance.getScannedResults();
    final out = <IcrewDevice>[];

    for (final ap in nets) {
      final ssid = ap.ssid;
      if (ssid.isEmpty) continue;
      final code = IcrewDevice.parseCodeFromSsid(ssid);
      if (code == null) continue;

      out.add(
        IcrewDevice(
          deviceCode: code,
          displayName: 'Icrew · $code',
          signalLabel: '${ap.level} dBm',
          sources: {IcrewDiscoverySource.provisioningHotspot},
          provisioningWifiSsid: ssid,
          preferredLanOrigin: null,
          signalDbm: ap.level,
        ),
      );
    }
    return out;
  }

  Future<List<IcrewDevice>> discoverLanMdns() async {
    final client = MDnsClient();
    const api = Esp32ApiClient();
    final found = <IcrewDevice>[];

    try {
      await client.start();

      await for (final ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_icrewPtrDomain),
        timeout: const Duration(seconds: 4),
      )) {
        final instanceFqdn = ptr.domainName;
        await for (final srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(instanceFqdn),
          timeout: const Duration(seconds: 3),
        )) {
          var target = srv.target;
          if (target.endsWith('.')) {
            target = target.substring(0, target.length - 1);
          }

          await for (final ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(target),
            timeout: const Duration(seconds: 2),
          )) {
            final origin = Uri(
              scheme: 'http',
              host: ip.address.address,
              port: srv.port == 80 ? null : srv.port,
            );

            final ping = await api.pingDevice(deviceBaseUri: origin);
            if (!ping.success || ping.data == null) continue;

            final raw = ping.data!['deviceCode'];
            if (raw is! String || raw.isEmpty) continue;
            final code = raw.toUpperCase();

            found.add(
              IcrewDevice(
                deviceCode: code,
                displayName: 'Icrew · $code',
                signalLabel: 'LAN',
                sources: {IcrewDiscoverySource.mdnsLan},
                provisioningWifiSsid: null,
                preferredLanOrigin: origin,
                signalDbm: null,
              ),
            );
          }
        }
      }
    } on Object {
      /* mDNS may fail on some networks — ignore */
    } finally {
      client.stop();
    }

    return _mergeByCode(found);
  }

  List<IcrewDevice> _mergeByCode(List<IcrewDevice> raw) {
    final map = <String, IcrewDevice>{};
    for (final d in raw) {
      final k = d.deviceCode.toUpperCase();
      map[k] = map.containsKey(k) ? map[k]!.merge(d) : d;
    }
    final list = map.values.toList()
      ..sort((a, b) => a.deviceCode.compareTo(b.deviceCode));
    return list;
  }
}
