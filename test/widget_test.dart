// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:navi_guardian/main.dart';

import 'package:provider/provider.dart';
import 'package:navi_guardian/models/navigation_data.dart';

void main() {
  testWidgets('Aira smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NavigationProvider(),
        child: const AiraApp(),
      ),
    );

    // Verify splash screen or app name text exists
    expect(find.text('AIRA'), findsOneWidget);
  });
}
