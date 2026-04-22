/// Mock device list for scan UI — replace with BLE/Wi‑Fi discovery later.
class MockDevice {
  const MockDevice({
    required this.id,
    required this.name,
    required this.signalLabel,
  });

  final String id;
  final String name;
  final String signalLabel;

  static const List<MockDevice> all = [
    MockDevice(
      id: 'esp32_001',
      name: 'ESP32_Device_1',
      signalLabel: 'Strong',
    ),
    MockDevice(
      id: 'esp32_cafe',
      name: 'ESP32_Cafe_Display',
      signalLabel: 'Good',
    ),
  ];
}
