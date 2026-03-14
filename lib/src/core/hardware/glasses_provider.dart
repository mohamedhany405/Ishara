import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hardware_connection_service.dart';

// ── Singleton service ──────────────────────────────────────────────────────
final hardwareServiceProvider = Provider<HardwareConnectionService>((ref) {
  final service = HardwareConnectionService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Connection state stream ────────────────────────────────────────────────
final hardwareStateProvider =
    StreamProvider<HardwareConnectionState>((ref) {
  return ref.watch(hardwareServiceProvider).stateStream;
});

// ── Latest sensor reading ──────────────────────────────────────────────────
final glassesSensorProvider = StreamProvider<HardwareMessage>((ref) {
  return ref.watch(hardwareServiceProvider).sensorStream;
});

// ── Discrete events (SOS, etc.) ────────────────────────────────────────────
final glassesEventProvider = StreamProvider<HardwareMessage>((ref) {
  return ref.watch(hardwareServiceProvider).eventStream;
});

// ── Raw audio PCM stream ───────────────────────────────────────────────────
final glassesAudioProvider = StreamProvider<Uint8List>((ref) {
  return ref.watch(hardwareServiceProvider).audioStream;
});

// ── Whether glasses are currently recording/streaming audio ────────────────
final glassesRecordingProvider = StreamProvider<bool>((ref) {
  return ref.watch(hardwareServiceProvider).recordingStateStream;
});

// ── Convenience: is glasses connected? ─────────────────────────────────────
final isGlassesConnectedProvider = Provider<bool>((ref) {
  final stateAsync = ref.watch(hardwareStateProvider);
  return stateAsync.whenOrNull(
        data: (s) => s == HardwareConnectionState.connected,
      ) ??
      false;
});
