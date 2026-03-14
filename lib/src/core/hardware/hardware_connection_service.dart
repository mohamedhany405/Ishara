import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Message envelope matching plan: type, id, payload.
class HardwareMessage {
  const HardwareMessage({
    required this.type,
    this.id,
    this.payload,
  });

  final String type;
  final String? id;
  final Map<String, dynamic>? payload;

  factory HardwareMessage.fromJson(Map<String, dynamic> json) {
    return HardwareMessage(
      type: json['type'] as String? ?? 'unknown',
      id: json['id'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (id != null) 'id': id,
        if (payload != null) 'payload': payload,
      };

  String toJsonString() => jsonEncode(toJson());
}

/// Connection state for hardware (ESP32 glasses/cane).
enum HardwareConnectionState { disconnected, connecting, connected, error }

/// Service that maintains WebSocket connection to ESP32 and exposes streams.
///
/// The ESP32 glasses run a WebSocket *server* on port 8080.
/// The app connects as a client to ws://<glasses-ip>:8080.
///
/// Incoming message types from glasses:
///   - sensor_update  : { distance_cm, timestamp }
///   - event          : { event: "sos", timestamp }
///   - audio_start    : { sample_rate, bits, channels }
///   - audio_data     : { b64: "<base64 PCM>" }
///   - audio_stop     : { duration_ms }
class HardwareConnectionService {
  HardwareConnectionService();

  WebSocketChannel? _channel;

  // ── Streams ──────────────────────────────────────────────────────────
  final StreamController<HardwareMessage> _sensorController =
      StreamController<HardwareMessage>.broadcast();
  final StreamController<HardwareMessage> _eventController =
      StreamController<HardwareMessage>.broadcast();
  final StreamController<HardwareConnectionState> _stateController =
      StreamController<HardwareConnectionState>.broadcast();
  final StreamController<Uint8List> _audioController =
      StreamController<Uint8List>.broadcast();
  final StreamController<bool> _recordingStateController =
      StreamController<bool>.broadcast();

  /// Obstacle / sensor readings from glasses.
  Stream<HardwareMessage> get sensorStream => _sensorController.stream;

  /// Discrete events (SOS, button presses).
  Stream<HardwareMessage> get eventStream => _eventController.stream;

  /// Connection state changes (emits current state immediately on listen).
  Stream<HardwareConnectionState> get stateStream async* {
    yield _state;
    yield* _stateController.stream;
  }

  /// Raw 16-bit PCM audio chunks from the glasses mic.
  Stream<Uint8List> get audioStream => _audioController.stream;

  /// true when the glasses are actively streaming audio (emits current value).
  Stream<bool> get recordingStateStream async* {
    yield _isRecording;
    yield* _recordingStateController.stream;
  }

  HardwareConnectionState _state = HardwareConnectionState.disconnected;
  HardwareConnectionState get state => _state;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  void _setState(HardwareConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  /// Connect to device at IP:port (e.g. 192.168.43.1:8080).
  Future<void> connect(String host, int port) async {
    if (_state == HardwareConnectionState.connected) return;
    _setState(HardwareConnectionState.connecting);
    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);
      // Wait for the WebSocket handshake with a timeout
      await _channel!.ready.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _channel?.sink.close();
          throw TimeoutException('Connection timed out — check IP and port');
        },
      );
      _setState(HardwareConnectionState.connected);
      _channel!.stream.listen(
        _onData,
        onError: (e) => _setState(HardwareConnectionState.error),
        onDone: () {
          _isRecording = false;
          _recordingStateController.add(false);
          _setState(HardwareConnectionState.disconnected);
        },
      );
    } catch (e) {
      _setState(HardwareConnectionState.error);
      rethrow;
    }
  }

  void _onData(dynamic data) {
    try {
      final map = jsonDecode(data is String ? data : data.toString())
          as Map<String, dynamic>;
      final msg = HardwareMessage.fromJson(map);
      switch (msg.type) {
        case 'sensor_update':
          _sensorController.add(msg);
          break;
        case 'event':
          _eventController.add(msg);
          break;
        case 'audio_start':
          _isRecording = true;
          _recordingStateController.add(true);
          break;
        case 'audio_data':
          final b64 = msg.payload?['b64'] as String?;
          if (b64 != null && b64.isNotEmpty) {
            _audioController.add(base64Decode(b64));
          }
          break;
        case 'audio_stop':
          _isRecording = false;
          _recordingStateController.add(false);
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  // ── Commands to glasses ──────────────────────────────────────────────

  void sendCommand(String action, [Map<String, dynamic>? params]) {
    if (_state != HardwareConnectionState.connected || _channel == null) return;
    final msg = HardwareMessage(
      type: 'command',
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      payload: {'action': action, ...?params},
    );
    _channel!.sink.add(msg.toJsonString());
  }

  void vibrate({String pattern = 'short_pulse'}) {
    sendCommand('vibrate', {'pattern': pattern});
  }

  /// Ask the glasses to start streaming audio.
  void startRecording() {
    sendCommand('start_recording');
  }

  /// Ask the glasses to stop streaming audio.
  void stopRecording() {
    sendCommand('stop_recording');
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isRecording = false;
    _recordingStateController.add(false);
    _setState(HardwareConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _sensorController.close();
    _eventController.close();
    _stateController.close();
    _audioController.close();
    _recordingStateController.close();
  }
}
