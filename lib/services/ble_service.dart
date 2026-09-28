import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'smart_stick_service.dart';

/// BLE communication layer for the ESP32 smart stick.
///
/// This service keeps the Guardian app's Bluetooth responsibilities in one place
/// instead of scattering device logic across screens. It implements real GATT
/// connection flow without mock/test fallback in the production BLE path.
enum BleConnectionState {
  idle,
  scanning,
  connecting,
  connected,
  disconnected,
  disabled,
  failed,
}

class DiscoveredBleDevice {
  final String name;
  final String address;
  final int rssi;
  final BluetoothDevice? device;

  DiscoveredBleDevice({
    required this.name,
    required this.address,
    required this.rssi,
    this.device,
  });
}

class BleService {
  BleService._();

  static final BleService instance = BleService._();

  static const String _stickName = 'AIRA-STICK';
  static const String _serviceUuid = '12345678-1234-1234-1234-123456789abc';
  static const String _commandCharacteristicUuid =
      '87654321-4321-4321-4321-abcdefabcdef';

  final StreamController<BleConnectionState> _stateController =
      StreamController<BleConnectionState>.broadcast();

  final StreamController<List<DiscoveredBleDevice>>
  _discoveredDevicesController =
      StreamController<List<DiscoveredBleDevice>>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _commandCharacteristic;
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _characteristicNotificationSubscription;

  bool _isScanning = false;
  bool _isConnected = false;
  bool _bluetoothEnabled = true;
  String _statusMessage = 'Disconnected';
  List<DiscoveredBleDevice> _discoveredDevices = [];

  Stream<BleConnectionState> get connectionState => _stateController.stream;
  Stream<List<DiscoveredBleDevice>> get discoveredDevices =>
      _discoveredDevicesController.stream;

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  bool get bluetoothEnabled => _bluetoothEnabled;
  String get statusMessage => _statusMessage;
  List<DiscoveredBleDevice> get currentDiscoveredDevices => _discoveredDevices;
  BluetoothDevice? get connectedDevice => _device;

  Future<List<DiscoveredBleDevice>> scanForStick({Duration? timeout}) async {
    if (!await FlutterBluePlus.isAvailable) {
      _bluetoothEnabled = false;
      _statusMessage = 'Bluetooth unavailable.';
      _stateController.add(BleConnectionState.disabled);
      _discoveredDevices = [];
      _discoveredDevicesController.add(_discoveredDevices);
      return [];
    }

    _isScanning = true;
    _statusMessage = 'Scanning for devices...';
    _stateController.add(BleConnectionState.scanning);
    _discoveredDevices = [];
    _discoveredDevicesController.add(_discoveredDevices);

    StreamSubscription? scanSubscription;
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      final seen = <String>{};
      final results = <DiscoveredBleDevice>[];

      scanSubscription = FlutterBluePlus.scanResults.listen((scanResults) {
        for (final r in scanResults) {
          final deviceName = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.device.remoteId.str;

          if (seen.contains(r.device.remoteId.str)) {
            final index = results.indexWhere((d) => d.address == r.device.remoteId.str);
            if (index != -1 && results[index].rssi != r.rssi) {
              results[index] = DiscoveredBleDevice(
                name: deviceName,
                address: r.device.remoteId.str,
                rssi: r.rssi,
                device: r.device,
              );
              _discoveredDevices = List.from(results);
              _discoveredDevicesController.add(_discoveredDevices);
            }
            continue;
          }

          seen.add(r.device.remoteId.str);
          results.add(
            DiscoveredBleDevice(
              name: deviceName,
              address: r.device.remoteId.str,
              rssi: r.rssi,
              device: r.device,
            ),
          );
          _discoveredDevices = List.from(results);
          _discoveredDevicesController.add(_discoveredDevices);
        }
      });

      await FlutterBluePlus.startScan(
        timeout: timeout ?? const Duration(seconds: 10),
        androidScanMode: AndroidScanMode.lowLatency,
        withNames: [_stickName],
        webOptionalServices: [Guid(_serviceUuid)],
      );

      // Wait until scan is finished
      await FlutterBluePlus.isScanning.firstWhere((isScanning) => !isScanning);

      _isScanning = false;
      _statusMessage = 'Found ${_discoveredDevices.length} device(s).';
      _stateController.add(BleConnectionState.idle);

      return _discoveredDevices;
    } catch (e) {
      _isScanning = false;
      final errorStr = e.toString();
      if (errorStr.contains('User cancelled') || errorStr.contains('NotFoundError') || errorStr.contains('cancelled')) {
        _statusMessage = 'Bluetooth device selection cancelled';
      } else {
        _statusMessage = 'Scan failed: $errorStr';
      }
      _stateController.add(BleConnectionState.failed);
      _discoveredDevices = [];
      _discoveredDevicesController.add(_discoveredDevices);

      developer.log('[BleService] Scan error: $e', name: 'BleService');
      return [];
    } finally {
      await scanSubscription?.cancel();
    }
  }

  Future<bool> connectToStick({String? deviceAddress}) async {
    if (!_bluetoothEnabled) {
      _statusMessage = 'Bluetooth disabled.';
      _stateController.add(BleConnectionState.disabled);
      return false;
    }

    // If no device address provided, scan for AIRA-STICK
    if (deviceAddress == null) {
      final discovered = await scanForStick();
      final airStick = discovered.firstWhere(
        (d) => d.name == _stickName,
        orElse: () => throw StateError('AIRA-STICK not found in scan results'),
      );
      deviceAddress = airStick.address;
    }

    // Find the device by address
    _statusMessage = 'Connecting to AIRA-STICK...';
    _stateController.add(BleConnectionState.connecting);

    try {
      // Find the device by address from discovered list first (crucial for Web)
      DiscoveredBleDevice? discovered;
      try {
        discovered = _discoveredDevices.firstWhere((d) => d.address == deviceAddress);
      } catch (_) {}

      BluetoothDevice? device = discovered?.device;
      if (device == null) {
        device = BluetoothDevice(remoteId: DeviceIdentifier(deviceAddress!));
      }
      _device = device;

      // Connect with timeout
      await device.connect(timeout: const Duration(seconds: 15));

      // Subscribe to connection state changes
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _statusMessage = 'Disconnected from AIRA-STICK.';
          _stateController.add(BleConnectionState.disconnected);
          _characteristicNotificationSubscription?.cancel();
          _characteristicNotificationSubscription = null;
          print('BLE DISCONNECTED');
          developer.log(
            '[BleService] Disconnected from AIRA-STICK',
            name: 'BleService',
          );
        }
      });

      // Discover services
      final services = await device.discoverServices();
      final matchingService = services.firstWhere(
        (service) =>
            service.uuid.toString().toUpperCase() == _serviceUuid.toUpperCase(),
        orElse: () => throw StateError('AIRA-STICK service not found'),
      );

      // Find characteristic
      final characteristic = matchingService.characteristics.firstWhere(
        (char) =>
            char.uuid.toString().toUpperCase() ==
            _commandCharacteristicUuid.toUpperCase(),
        orElse: () =>
            throw StateError('AIRA-STICK command characteristic not found'),
      );

      _commandCharacteristic = characteristic;

      // Add a small delay for GATT stability on Web
      await Future.delayed(const Duration(milliseconds: 500));

      // Subscribe to notifications on that characteristic (register listener FIRST)
      _characteristicNotificationSubscription?.cancel();
      _characteristicNotificationSubscription = characteristic.onValueReceived.listen((value) {
        final dataStr = utf8.decode(value);
        developer.log('[BleService] Received data: $dataStr', name: 'BleService');
        _parseAndProcessTelemetry(dataStr);
      });

      try {
        await characteristic.setNotifyValue(true);
      } catch (e) {
        developer.log(
          '[BleService] Warning: setNotifyValue failed or timed out, but proceeding: $e',
          name: 'BleService',
        );
      }

      _isConnected = true;
      _statusMessage = 'AIRA-STICK Connected';
      _stateController.add(BleConnectionState.connected);

      developer.log(
        '[BleService] Successfully connected to AIRA-STICK at $deviceAddress',
        name: 'BleService',
      );
      return true;
    } catch (e) {
      _isConnected = false;
      _device = null;
      _commandCharacteristic = null;
      _characteristicNotificationSubscription?.cancel();
      _characteristicNotificationSubscription = null;
      _statusMessage = 'Connection failed: ${e.toString()}';
      _stateController.add(BleConnectionState.failed);

      developer.log('[BleService] Connection failed: $e', name: 'BleService');
      return false;
    }
  }

  Future<void> disconnectFromStick() async {
    try {
      if (_device != null) {
        await _device!.disconnect();
      }
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
      _characteristicNotificationSubscription?.cancel();
      _characteristicNotificationSubscription = null;
    } catch (e) {
      developer.log('[BleService] Disconnect error: $e', name: 'BleService');
    } finally {
      _commandCharacteristic = null;
      _isConnected = false;
      _statusMessage = 'Disconnected from AIRA-STICK.';
      _stateController.add(BleConnectionState.disconnected);

      developer.log(
        '[BleService] Disconnected from AIRA-STICK',
        name: 'BleService',
      );
    }
  }

  Future<void> reconnectToStick() async {
    if (!_isConnected && _device != null) {
      await connectToStick(deviceAddress: _device!.remoteId.str);
    }
  }

  /// Send a command to the AIRA-STICK via the BLE characteristic.
  /// Only succeeds if connected to a real device.
  /// Throws exception if not connected or write fails.
  Future<bool> sendCommand(String command) async {
    final normalized = command.trim();
    if (normalized.isEmpty) {
      return false;
    }

    // BLE Connected check
    if (!_isConnected || _device == null) {
      print('BLE WRITE FAILED: $normalized');
      print('ERROR: BLE Device not connected');
      developer.log('BLE WRITE FAILED: $normalized. Error: BLE Device not connected', name: 'BleService');
      return false;
    }

    // Correct device check
    final deviceName = _device!.platformName;
    if (deviceName != _stickName) {
      print('BLE WRITE FAILED: $normalized');
      print('ERROR: Incorrect device connected: $deviceName');
      developer.log('BLE WRITE FAILED: $normalized. Error: Incorrect device connected: $deviceName', name: 'BleService');
      return false;
    }

    print('BLE connected');
    developer.log('BLE connected', name: 'BleService');

    // Writable characteristic check
    if (_commandCharacteristic == null) {
      print('BLE WRITE FAILED: $normalized');
      print('ERROR: Characteristic is null');
      developer.log('BLE WRITE FAILED: $normalized. Error: Characteristic is null', name: 'BleService');
      return false;
    }

    // Characteristic supports write check
    final props = _commandCharacteristic!.properties;
    if (!props.write && !props.writeWithoutResponse) {
      print('BLE WRITE FAILED: $normalized');
      print('ERROR: Characteristic does not support write operations');
      developer.log('BLE WRITE FAILED: $normalized. Error: Characteristic does not support write operations', name: 'BleService');
      return false;
    }

    print('BLE characteristic ready');
    developer.log('BLE characteristic ready', name: 'BleService');

    print('BLE write attempt');
    developer.log('BLE write attempt', name: 'BleService');

    try {
      final bytes = utf8.encode(normalized);
      await _commandCharacteristic!.write(bytes, withoutResponse: false);
      _statusMessage = 'Sent to AIRA-STICK: $normalized';

      print('BLE write completed');
      developer.log('BLE write completed', name: 'BleService');
      print('BLE WRITE SUCCESS: $normalized');
      developer.log('BLE WRITE SUCCESS: $normalized', name: 'BleService');
      return true;
    } catch (e) {
      _statusMessage = 'Failed to send command: ${e.toString()}';
      _stateController.add(BleConnectionState.failed);

      print('BLE WRITE FAILED: $normalized');
      print('ERROR: $e');
      developer.log('BLE WRITE FAILED: $normalized. Error: $e', name: 'BleService');
      return false;
    }
  }

  Future<void> listenForStickStatus() async {
    _statusMessage = _isConnected
        ? 'Connected to AIRA-STICK.'
        : 'Disconnected. Tap "Connect Smart Stick" to connect.';
    developer.log('[BleService] Status: $_statusMessage', name: 'BleService');
  }

  void setBluetoothEnabled(bool enabled) {
    _bluetoothEnabled = enabled;
    if (!enabled) {
      _isConnected = false;
      _statusMessage = 'Bluetooth disabled.';
      _stateController.add(BleConnectionState.disabled);
    }
  }

  void _parseAndProcessTelemetry(String dataStr) {
    try {
      final cleanData = dataStr.trim().toUpperCase();
      if (cleanData.startsWith('VOICE_PLAYED:')) {
        print('ESP32 ACK: $cleanData');
        developer.log('ESP32 ACK: $cleanData', name: 'BleService');
        return;
      }

      if (cleanData == 'DESTINATION_AUDIO_DONE') {
        SmartStickService.instance.emitMockEvent(
          SmartStickEventType.DESTINATION_AUDIO_DONE,
          'DESTINATION_AUDIO_DONE received',
        );
        return;
      }

      final parts = dataStr.split(',');
      double? frontVal;
      double? pitVal;
      String? waterVal;

      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          final key = kv[0].trim().toUpperCase();
          final val = kv[1].trim();
          if (key == 'FRONT') {
            frontVal = _parseDistanceValue(val);
          } else if (key == 'PIT') {
            pitVal = _parseDistanceValue(val);
          } else if (key == 'WATER') {
            waterVal = val.toUpperCase();
          }
        }
      }

      if (frontVal != null || pitVal != null || waterVal != null) {
        final frontDistanceCm = frontVal?.round();
        final pitDistanceCm = pitVal?.round();
        final waterDetected = waterVal != null ? (waterVal != 'CLEAR') : null;

        SmartStickService.instance.emitTelemetryEvent(
          frontDistanceCm: frontDistanceCm,
          pitDistanceCm: pitDistanceCm,
          waterDetected: waterDetected,
          rawMessage: dataStr,
        );
      }
    } catch (e) {
      developer.log('[BleService] Error parsing telemetry: $e', name: 'BleService');
    }
  }

  double? _parseDistanceValue(String val) {
    final numericStr = val.replaceAll('cm', '').replaceAll(RegExp(r'[^\d\.]'), '').trim();
    return double.tryParse(numericStr);
  }

  void dispose() {
    _connectionStateSubscription?.cancel();
    _characteristicNotificationSubscription?.cancel();
    _stateController.close();
    _discoveredDevicesController.close();
  }
}
