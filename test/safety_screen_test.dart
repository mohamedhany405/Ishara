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
      await tester.pumpAndSettle();
      expect(find.text('Safety'), findsOneWidget);
      expect(find.textContaining('Obstacle'), findsAtLeast(1));
      expect(find.textContaining('SOS'), findsAtLeast(1));
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
      await tester.pumpAndSettle();
      final sosSemantics = find.bySemanticsLabel('Open SOS emergency screen');
      expect(sosSemantics, findsOneWidget);
    });
  });
}
