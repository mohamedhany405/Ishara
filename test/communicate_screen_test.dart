import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ishara_app/src/core/api/auth_provider.dart';
import 'package:ishara_app/src/features/communicate/presentation/communicate_screen.dart';

void main() {
  group('CommunicateScreen', () {
    late SharedPreferences prefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('renders title and direction chip', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(home: CommunicateScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CommunicateScreen), findsOneWidget);
      expect(find.byIcon(Icons.videocam_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('Live translation controls are visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(home: CommunicateScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.memory_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });
  });
}
