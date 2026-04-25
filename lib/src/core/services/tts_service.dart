/// Global TTS service used by every feature (translator, vision, learning,
/// auto-TTS, chatbot).
///
/// Wraps [flutter_tts]. Honors a queue mode so sequential `speak()` calls play
/// in order. Locale defaults to ar-EG and can be changed at runtime.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService() {
    _tts.setSharedInstance(true);
    _tts.awaitSpeakCompletion(true);
    _tts.setLanguage('ar-EG');
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  final FlutterTts _tts = FlutterTts();
  bool _muted = false;

  void setMuted(bool m) {
    _muted = m;
    if (m) _tts.stop();
  }

  Future<void> setLanguage(String code) => _tts.setLanguage(code);
  Future<void> setRate(double r) => _tts.setSpeechRate(r.clamp(0.2, 1.0));

  Future<void> speak(String text) async {
    if (_muted || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() => _tts.stop();
}

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
