import 'package:flutter_test/flutter_test.dart';

import 'package:ishara_app/src/core/hardware/hardware_connection_service.dart';

void main() {
  group('HardwareMessage', () {
    test('fromJson parses type, id, payload', () {
      final msg = HardwareMessage.fromJson({
        'type': 'sensor_update',
        'id': '123',
        'payload': {'distance': 42},
      });
      expect(msg.type, 'sensor_update');
      expect(msg.id, '123');
      expect(msg.payload, {'distance': 42});
    });

    test('fromJson defaults type to unknown when missing', () {
      final msg = HardwareMessage.fromJson({'id': 'x'});
      expect(msg.type, 'unknown');
      expect(msg.id, 'x');
    });

    test('toJson round-trip', () {
      const msg = HardwareMessage(
        type: 'event',
        id: 'evt1',
        payload: {'name': 'obstacle'},
      );
      final map = Map<String, dynamic>.from(msg.toJson());
      final restored = HardwareMessage.fromJson(map);
      expect(restored.type, msg.type);
      expect(restored.id, msg.id);
      expect(restored.payload, msg.payload);
    });
  });
}
