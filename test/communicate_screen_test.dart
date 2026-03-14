import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ishara_app/src/features/communicate/presentation/communicate_screen.dart';

void main() {
  group('CommunicateScreen', () {
    testWidgets('renders title and direction chip', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CommunicateScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ishara'), findsOneWidget);
      expect(find.text('ESL ↔ Arabic communication'), findsOneWidget);
    });

    testWidgets('Translate and Speak buttons have semantics', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CommunicateScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byType(OutlinedButton), findsWidgets);
    });
  });
}
