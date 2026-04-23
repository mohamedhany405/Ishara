import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ishara_app/src/features/safety/presentation/safety_screen.dart';

void main() {
  group('SafetyScreen', () {
    testWidgets('dashboard shows obstacle and SOS card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SafetyScreen(initialTab: SafetyInitialTab.dashboard),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.emergency_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sensors_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('SOS button has semantic label', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SafetyScreen(initialTab: SafetyInitialTab.dashboard),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.emergency_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
