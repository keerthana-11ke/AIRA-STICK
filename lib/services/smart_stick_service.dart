import 'dart:async';
import 'dart:developer' as developer;

import 'ble_service.dart';
import 'navigation_command_service.dart';

enum SmartStickEventType {
  OBSTACLE_DETECTED,
  PIT_DETECTED,
  WATER_DETECTED,
  SOS_TRIGGERED,
  COMMAND_SENT,
  COMMAND_FAILED,
  DISCONNECTED,
  TELEMETRY_UPDATED,
  DESTINATION_AUDIO_DONE,
}

class SmartStickEvent {
  final SmartStickEventType type;
  final String message;
  final DateTime timestamp;
  
  // Parsed telemetry fields
  final int? frontDistanceCm;
  final int? pitDistanceCm;
  final bool? waterDetected;

  SmartStickEvent({
    required this.type,
    required this.message,
    this.frontDistanceCm,
    this.pitDistanceCm,
    this.waterDetected,
  }) : timestamp = DateTime.now();
}

/// Singleton service representing the modular communication layer to the
/// smart stick (ESP32). It delegates BLE operations to BleService and
/// keeps app-level event streaming separate from low-level device logic.
///
/// NOTE: This service no longer has mock/test mode in the production BLE path.
/// Real hardware connection is required for command delivery.
class SmartStickService {
  SmartStickService._internal();

  static final SmartStickService instance = SmartStickService._internal();

  final StreamController<SmartStickEvent> _events =
      StreamController.broadcast();

  Stream<SmartStickEvent> get events => _events.stream;

  /// Scan for available BLE devices.
  Future<List<DiscoveredBleDevice>> scanForDevices({Duration? timeout}) async {
    return BleService.instance.scanForStick(timeout: timeout);
  }

  /// Connect to a specific BLE device by address.
  Future<bool> connectToDevice(String deviceAddress) async {
    return BleService.instance.connectToStick(deviceAddress: deviceAddress);
  }

  /// Send a command through the real BLE characteristic.
  /// Returns true if delivery succeeded, false if not connected.
  Future<bool> sendCommand(String command) async {
    developer.log(
      '[SmartStickService] sendCommand: $command',
      name: 'SmartStickService',
    );

    final normalized = command.trim();
    if (normalized.isEmpty) {
      return false;
    }

    // Normalize the command (standardize format if needed)
    final normalizedCmd = NavigationCommandService.normalizeCommand(normalized);

    // Send through real BLE
    final success = await BleService.instance.sendCommand(normalizedCmd);

    if (success) {
      _events.add(
        SmartStickEvent(
          type: SmartStickEventType.COMMAND_SENT,
          message: 'Command sent to AIRA-STICK: $normalizedCmd',
        ),
      );
    } else {
      _events.add(
        SmartStickEvent(
          type: SmartStickEventType.COMMAND_FAILED,
          message: 'Failed to send command: $normalizedCmd',
        ),
      );
    }

    return success;
  }

  Future<bool> sendNavigationCommand(String command) async {
    return await sendCommand(command);
  }

  Future<bool> scanForStick() async {
    final results = await BleService.instance.scanForStick();
    return results.isNotEmpty;
  }

  Future<bool> connectToStick() async {
    return BleService.instance.connectToStick();
  }

  Future<void> disconnectFromStick() async {
    await BleService.instance.disconnectFromStick();
    _events.add(
      SmartStickEvent(
        type: SmartStickEventType.DISCONNECTED,
        message: 'Disconnected from AIRA-STICK.',
      ),
    );
  }

  Future<void> connect() async {
    developer.log('[SmartStickService] connect()', name: 'SmartStickService');
    await connectToStick();
  }

  Future<void> disconnect() async {
    developer.log(
      '[SmartStickService] disconnect()',
      name: 'SmartStickService',
    );
    await disconnectFromStick();
  }

  bool getConnectionStatus() => BleService.instance.isConnected;

  void emitTelemetryEvent({
    int? frontDistanceCm,
    int? pitDistanceCm,
    bool? waterDetected,
    required String rawMessage,
  }) {
    _events.add(
      SmartStickEvent(
        type: SmartStickEventType.TELEMETRY_UPDATED,
        message: rawMessage,
        frontDistanceCm: frontDistanceCm,
        pitDistanceCm: pitDistanceCm,
        waterDetected: waterDetected,
      ),
    );
  }

  /// Emit a mock/test event ONLY for development/UI testing purposes.
  /// This does NOT send real BLE commands; use only when testing without hardware.
  /// MARK CALLS TO THIS AS "TEST ONLY" in the UI.
  void emitMockEvent(SmartStickEventType type, String message) {
    final ev = SmartStickEvent(type: type, message: message);
    developer.log(
      '[SmartStickService] [TEST ONLY] emitMockEvent: ${ev.type} ${ev.message}',
      name: 'SmartStickService',
    );
    _events.add(ev);
  }

  void dispose() {
    _events.close();
  }
}
