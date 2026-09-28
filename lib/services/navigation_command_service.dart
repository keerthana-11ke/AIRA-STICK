import 'dart:developer' as developer;

import 'ble_service.dart';

/// Central transport layer for Guardian-to-ESP32 navigation commands.
///
/// The app keeps BLE responsibilities in one service so screens do not duplicate
/// connection or command logic. This version supports the expected AIRA-STICK
/// command names and degrades to a clear mock/test mode when the physical stick
/// is unavailable.
class NavigationCommandService {
  NavigationCommandService._();

  static Future<bool> sendNavigationCommand(String command) async {
    final normalized = normalizeCommand(command);
    developer.log(
      '[NavigationCommandService] $normalized',
      name: 'NavigationCommandService',
    );

    return await BleService.instance.sendCommand(normalized);
  }

  static String normalizeCommand(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return 'NAVIGATION_CANCELLED';

    final lower = trimmed.toLowerCase();
    if (lower.contains('destination')) {
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex != -1) {
        final suffix = trimmed.substring(colonIndex + 1).trim();
        return 'DESTINATION_SELECTED:$suffix';
      }
      return 'DESTINATION_SELECTED';
    }

    final upper = trimmed.toUpperCase();

    if (upper.contains('TURN LEFT')) return 'TURN_LEFT';
    if (upper.contains('TURN_LEFT')) return 'TURN_LEFT';
    if (upper.contains('TURN RIGHT')) return 'TURN_RIGHT';
    if (upper.contains('TURN_RIGHT')) return 'TURN_RIGHT';
    if (upper.contains('GO STRAIGHT')) return 'STRAIGHT';
    if (upper.contains('STRAIGHT')) return 'STRAIGHT';
    if (upper.contains('ARRIVED')) return 'ARRIVED';
    if (upper.contains('CANCEL')) return 'NAVIGATION_CANCELLED';

    return upper.replaceAll(RegExp(r'\s+'), '_');
  }
}
