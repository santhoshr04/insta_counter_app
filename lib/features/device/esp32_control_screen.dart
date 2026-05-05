import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insta_counter_app/core/models/icrew_device.dart';
import 'package:insta_counter_app/core/services/esp32_api_client.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/providers/device_hub_notifier.dart';
import 'package:provider/provider.dart';

class Esp32ControlScreen extends StatefulWidget {
  const Esp32ControlScreen({
    super.key,
    required this.deviceName,
    this.pickedDevice,
  });

  final String deviceName;
  final IcrewDevice? pickedDevice;

  @override
  State<Esp32ControlScreen> createState() => _Esp32ControlScreenState();
}

class _Esp32ControlScreenState extends State<Esp32ControlScreen> {
  final _api = const Esp32ApiClient();
  final _originCtrl = TextEditingController();
  final _cmdCtrl = TextEditingController();
  bool _busy = false;
  String? _lastStatusJson;
  String? _lastJokeFromDevice;

  static const _quickCommands = <String>[
    'run',
    'stop',
    'continuous on',
    'continuous off',
    'interval on',
    'interval off',
    'status',
    'help',
    'joke on',
    'joke off',
  ];

  String _defaultOriginHint() {
    final d = widget.pickedDevice;
    if (d == null) {
      return 'http://icrew.local or LAN IP';
    }
    if (d.preferredLanOrigin != null) {
      return d.preferredLanOrigin.toString();
    }
    if (d.sources.contains(IcrewDiscoverySource.provisioningHotspot) &&
        !d.sources.contains(IcrewDiscoverySource.mdnsLan)) {
      return 'http://192.168.4.1 (on device hotspot)';
    }
    return 'http://icrew-${d.deviceCode.toLowerCase()}.local';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final d = widget.pickedDevice;
      final hub = context.read<DeviceHubNotifier>();
      if (d?.preferredLanOrigin != null) {
        _originCtrl.text = d!.preferredLanOrigin!.toString();
      } else if (d != null &&
          d.sources.contains(IcrewDiscoverySource.provisioningHotspot) &&
          !d.sources.contains(IcrewDiscoverySource.mdnsLan)) {
        _originCtrl.text = 'http://192.168.4.1';
      } else if (d != null) {
        _originCtrl.text = 'http://icrew-${d.deviceCode.toLowerCase()}.local';
      } else {
        _originCtrl.text = hub.origin.toString();
      }
    });
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _cmdCtrl.dispose();
    super.dispose();
  }

  Future<Uri?> _validatedOrigin() async {
    try {
      return _api.normalizeBaseUri(_originCtrl.text);
    } on FormatException catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return null;
    }
  }

  Future<void> _persistOrigin(Uri o) async {
    await context.read<DeviceHubNotifier>().setOrigin(o);
  }

  Future<void> _send(String cmd, {Uri? explicit}) async {
    final trimmed = cmd.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Empty command.', style: GoogleFonts.dmSans())),
      );
      return;
    }

    final origin = explicit ?? await _validatedOrigin();
    if (origin == null) return;
    setState(() => _busy = true);
    try {
      final res = await _api.sendCommand(deviceBaseUri: origin, cmd: trimmed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.success ? 'Sent: $trimmed' : (res.errorMessage ?? ''),
            style: GoogleFonts.dmSans(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pullStatus({Uri? explicit}) async {
    final origin = explicit ?? await _validatedOrigin();
    if (origin == null) return;
    setState(() => _busy = true);
    try {
      final res = await _api.fetchStatus(deviceBaseUri: origin);
      if (!mounted) return;
      if (!res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Status failed'),
          ),
        );
        return;
      }
      final pretty = const JsonEncoder.withIndent('  ').convert(res.data);
      setState(() => _lastStatusJson = pretty);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fetchJokeFromEsp32() async {
    final origin = await _validatedOrigin();
    if (origin == null) return;
    setState(() => _busy = true);
    try {
      final res = await _api.fetchJokeFromDevice(deviceBaseUri: origin);
      if (!mounted) return;
      if (!res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.errorMessage ?? 'Joke request failed')),
        );
        return;
      }
      setState(() => _lastJokeFromDevice = res.data);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _factory() async {
    final origin = await _validatedOrigin();
    if (origin == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Factory reset firmware?'),
        content: const Text(
          'Clears saved Wi‑Fi on the ESP32 and reboots. You will need provisioning again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Erase & reboot'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final res = await _api.factoryReset(deviceBaseUri: origin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.success ? 'Factory reset queued' : '${res.errorMessage}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Control · ${widget.deviceName}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Device URL',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _originCtrl,
            enabled: !_busy,
            decoration: InputDecoration(
              hintText: _defaultOriginHint(),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            style: GoogleFonts.dmSans(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        final o = await _validatedOrigin();
                        if (o == null) return;
                        await _persistOrigin(o);
                        await _pullStatus(explicit: o);
                      },
                child: const Text('Save & fetch status'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _busy ? null : _factory,
                child: const Text('Factory reset'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Joke (from ESP32)',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'The phone does not call jokeapi.dev. The ESP32 fetches the joke; '
            'this button reads /api/joke from the board.',
            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: _busy ? null : _fetchJokeFromEsp32,
            child: Text('Get joke from device', style: GoogleFonts.dmSans()),
          ),
          if (_lastJokeFromDevice != null) ...[
            const SizedBox(height: 12),
            SelectionArea(
              child: Text(
                _lastJokeFromDevice!,
                style: GoogleFonts.dmSans(fontSize: 14, height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text('Quick commands', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickCommands
                .map(
                  (q) => ActionChip(
                    label: Text(q, style: GoogleFonts.dmSans(fontSize: 12)),
                    onPressed: _busy ? null : () => _send(q),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text('Custom UART line', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _cmdCtrl,
            decoration: InputDecoration(
              hintText: 'steps 512',
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: _busy
                    ? null
                    : () async {
                        final t = _cmdCtrl.text.trim();
                        if (t.isEmpty) return;
                        await _send(t);
                        if (mounted) _cmdCtrl.clear();
                      },
              ),
            ),
            style: GoogleFonts.dmSans(),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) async {
              final t = _cmdCtrl.text.trim();
              if (t.isEmpty || _busy) return;
              await _send(t);
              if (mounted) _cmdCtrl.clear();
            },
          ),
          if (_lastStatusJson != null) ...[
            const SizedBox(height: 22),
            Text('Last status', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SelectionArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_lastStatusJson!, style: GoogleFonts.dmMono(fontSize: 11)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
