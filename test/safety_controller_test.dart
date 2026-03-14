import 'package:flutter_test/flutter_test.dart';

import 'package:ishara_app/src/features/safety/presentation/safety_controller.dart';

void main() {
  group('SafetyController', () {
    late SafetyController controller;

    setUp(() {
      controller = SafetyController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is dashboard and idle', () {
      expect(controller.state.currentTab, SafetyTab.dashboard);
      expect(controller.state.sosPhase, SosPhase.idle);
    });

    test('switchTab updates currentTab', () {
      controller.switchTab(SafetyTab.sos);
      expect(controller.state.currentTab, SafetyTab.sos);
    });

    test('armSos sets phase to armed', () async {
      await controller.armSos();
      expect(controller.state.sosPhase, SosPhase.armed);
    });

    test('cancelSos resets phase to idle after delay', () async {
      await controller.armSos();
      controller.startSosCountdown();
      controller.cancelSos();
      expect(controller.state.sosPhase, SosPhase.cancelled);
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(controller.state.sosPhase, SosPhase.idle);
    });

    test('resetSos sets phase to idle', () async {
      await controller.armSos();
      controller.resetSos();
      expect(controller.state.sosPhase, SosPhase.idle);
    });
  });

  group('ObstacleReading', () {
    test('ObstacleReading holds values', () {
      final now = DateTime.now();
      final r = ObstacleReading(
        distanceCm: 30,
        leftCm: 25,
        rightCm: 28,
        timestamp: now,
      );
      expect(r.distanceCm, 30);
      expect(r.leftCm, 25);
      expect(r.timestamp, now);
    });
  });
}
