import 'package:flutter_test/flutter_test.dart';
import 'package:navi_guardian/services/navigation_command_service.dart';

void main() {
  group('NavigationCommandService', () {
    test('normalizes the required AIRA-STICK command names', () {
      expect(
        NavigationCommandService.normalizeCommand('turn left'),
        'TURN_LEFT',
      );
      expect(
        NavigationCommandService.normalizeCommand('turn right'),
        'TURN_RIGHT',
      );
      expect(
        NavigationCommandService.normalizeCommand('go straight'),
        'STRAIGHT',
      );
      expect(
        NavigationCommandService.normalizeCommand('you have arrived'),
        'ARRIVED',
      );
      expect(
        NavigationCommandService.normalizeCommand('cancel navigation'),
        'NAVIGATION_CANCELLED',
      );
      expect(
        NavigationCommandService.normalizeCommand('destination selected'),
        'DESTINATION_SELECTED',
      );
    });
  });
}
