import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hardware/glasses_provider.dart';
import '../data/esl_translator_service.dart';
import '../data/sign_language_service.dart';
import '../data/speech_io_service.dart';
import '../domain/esl_translation_models.dart';

class TranslatorState {
  const TranslatorState({
    required this.direction,
    required this.inputText,
    required this.outputText,
    required this.isTranslating,
    required this.isListening,
    required this.isCameraActive,
    required this.error,
    required this.lastResult,
    required this.audioSource,
    required this.isModelReady,
    required this.hasCameraPermission,
    required this.cameraPermissionPermanentlyDenied,
    required this.handsDetected,
    required this.faceDetected,
    required this.lowLight,
    required this.ambientBrightness,
    required this.framesCollected,
    required this.framesNeeded,
    required this.lastDetectedWord,
    required this.detectionConfidence,
    required this.detectedSentence,
    required this.streamFps,
    required this.sentFrames,
    required this.droppedFrames,
  });

  final EslTranslationDirection direction;
  final String inputText;
  final String outputText;
  final bool isTranslating;
  final bool isListening;
  final bool isCameraActive;
  final String? error;
  final EslTranslationResult? lastResult;
  final AudioSource audioSource;

  // On-device sign model state
  final bool isModelReady;
  final bool hasCameraPermission;
  final bool cameraPermissionPermanentlyDenied;
  final bool handsDetected;
  final bool faceDetected;
  final bool lowLight;
  final double ambientBrightness;
  final int framesCollected;
  final int framesNeeded;
  final String lastDetectedWord;
  final double detectionConfidence;
  final String detectedSentence;
  final double streamFps;
  final int sentFrames;
  final int droppedFrames;

  TranslatorState copyWith({
    EslTranslationDirection? direction,
    String? inputText,
    String? outputText,
    bool? isTranslating,
    bool? isListening,
    bool? isCameraActive,
    String? error,
    EslTranslationResult? lastResult,
    AudioSource? audioSource,
    bool? isModelReady,
    bool? hasCameraPermission,
    bool? cameraPermissionPermanentlyDenied,
    bool? handsDetected,
    bool? faceDetected,
    bool? lowLight,
    double? ambientBrightness,
    int? framesCollected,
    int? framesNeeded,
    String? lastDetectedWord,
    double? detectionConfidence,
    String? detectedSentence,
    double? streamFps,
    int? sentFrames,
    int? droppedFrames,
  }) {
    return TranslatorState(
      direction: direction ?? this.direction,
      inputText: inputText ?? this.inputText,
      outputText: outputText ?? this.outputText,
      isTranslating: isTranslating ?? this.isTranslating,
      isListening: isListening ?? this.isListening,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      error: error,
      lastResult: lastResult ?? this.lastResult,
      audioSource: audioSource ?? this.audioSource,
      isModelReady: isModelReady ?? this.isModelReady,
      hasCameraPermission: hasCameraPermission ?? this.hasCameraPermission,
      cameraPermissionPermanentlyDenied:
          cameraPermissionPermanentlyDenied ??
          this.cameraPermissionPermanentlyDenied,
      handsDetected: handsDetected ?? this.handsDetected,
      faceDetected: faceDetected ?? this.faceDetected,
      lowLight: lowLight ?? this.lowLight,
      ambientBrightness: ambientBrightness ?? this.ambientBrightness,
      framesCollected: framesCollected ?? this.framesCollected,
      framesNeeded: framesNeeded ?? this.framesNeeded,
      lastDetectedWord: lastDetectedWord ?? this.lastDetectedWord,
      detectionConfidence: detectionConfidence ?? this.detectionConfidence,
      detectedSentence: detectedSentence ?? this.detectedSentence,
      streamFps: streamFps ?? this.streamFps,
      sentFrames: sentFrames ?? this.sentFrames,
      droppedFrames: droppedFrames ?? this.droppedFrames,
    );
  }

  factory TranslatorState.initial() => const TranslatorState(
    direction: EslTranslationDirection.eslToArabic,
    inputText: '',
    outputText: '',
    isTranslating: false,
    isListening: false,
    isCameraActive: false,
    error: null,
    lastResult: null,
    audioSource: AudioSource.phoneMic,
    isModelReady: false,
    hasCameraPermission: false,
    cameraPermissionPermanentlyDenied: false,
    handsDetected: false,
    faceDetected: false,
    lowLight: false,
    ambientBrightness: 0,
    framesCollected: 0,
    framesNeeded: 30,
    lastDetectedWord: '',
    detectionConfidence: 0.0,
    detectedSentence: '',
    streamFps: 0,
    sentFrames: 0,
    droppedFrames: 0,
  );
}

class TranslatorController extends StateNotifier<TranslatorState> {
  TranslatorController({
    required EslTranslator translator,
    required SpeechIoService speechIo,
    required SignLanguageService signService,
  }) : _translator = translator,
       _speechIo = speechIo,
       _signService = signService,
       super(TranslatorState.initial()) {
    _initSignService();
  }

  final EslTranslator _translator;
  final SpeechIoService _speechIo;
  final SignLanguageService _signService;

  void _initSignService() {
    _signService.onConnectionChanged = (connected) {
      if (!mounted) return;
      state = state.copyWith(
        isModelReady: connected,
        isCameraActive: connected ? state.isCameraActive : false,
      );
    };

    _signService.onPrediction = (result) {
      if (!mounted) return;
      final sentence = result.sentence.trim();
      final word = result.word.trim();
      final output = sentence.isNotEmpty ? sentence : word;

      state = state.copyWith(
        lastDetectedWord: result.word,
        detectionConfidence: result.confidence,
        detectedSentence: result.sentence,
        outputText: output,
        handsDetected: result.handsDetected,
        faceDetected: result.faceDetected,
        lowLight: result.lowLight,
        ambientBrightness: result.ambientBrightness,
        framesCollected: result.framesCollected,
        framesNeeded: result.framesNeeded,
      );

      _speakDetectedWord(result.word);
    };

    _signService.onStatus = (status) {
      if (!mounted) return;
      state = state.copyWith(
        handsDetected: status.handsDetected,
        faceDetected: status.faceDetected,
        lowLight: status.lowLight,
        ambientBrightness: status.ambientBrightness,
        framesCollected: status.framesCollected,
        framesNeeded: status.framesNeeded,
      );
    };

    _signService.onMetrics = (metrics) {
      if (!mounted) return;
      state = state.copyWith(
        streamFps: metrics.outgoingFps,
        sentFrames: metrics.sentFrames,
        droppedFrames: metrics.droppedFrames,
      );
    };

    _signService.onError = (error) {
      if (!mounted) return;
      state = state.copyWith(error: _mapSignServiceError(error));
    };
  }

  String _mapSignServiceError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('camera')) {
      return 'Camera initialization failed. Please retry or restart the app.';
    }
    if (lower.contains('model') ||
        lower.contains('label') ||
        lower.contains('asset')) {
      return 'On-device model loading failed. Verify asl_v6.tflite, label_map_v6.json, and manifest.json in assets/models.';
    }
    if (lower.contains('android/ios only') || lower.contains('web')) {
      return 'Offline sign detection is currently available on Android and iOS builds.';
    }
    if (lower.contains('failed precondition')) {
      return 'Camera stream temporarily desynchronized. Recovery is automatic; if this repeats, stop and start the camera once.';
    }
    return error;
  }

  Future<void> _speakDetectedWord(String word) async {
    if (word.trim().isEmpty) return;
    await _speechIo.setTtsLanguage('ar-SA');
    await _speechIo.speak(word);
  }

  void setInput(String text) {
    state = state.copyWith(inputText: text, error: null);
  }

  void setAudioSource(AudioSource source) {
    state = state.copyWith(audioSource: source);
  }

  void setCameraPermission({
    required bool granted,
    bool permanentlyDenied = false,
  }) {
    state = state.copyWith(
      hasCameraPermission: granted,
      cameraPermissionPermanentlyDenied: permanentlyDenied,
      error: null,
    );
  }

  void toggleDirection() {
    final next =
        state.direction == EslTranslationDirection.eslToArabic
            ? EslTranslationDirection.arabicToEsl
            : EslTranslationDirection.eslToArabic;

    if (state.isCameraActive) {
      _signService.stopStreaming();
    }

    state = state.copyWith(
      direction: next,
      inputText: '',
      outputText: '',
      error: null,
      isCameraActive: false,
      handsDetected: false,
      faceDetected: false,
      lowLight: false,
      ambientBrightness: 0,
      lastDetectedWord: '',
      detectionConfidence: 0.0,
      detectedSentence: '',
      streamFps: 0,
      sentFrames: 0,
      droppedFrames: 0,
    );
  }

  Future<void> translate() async {
    if (state.inputText.trim().isEmpty || state.isTranslating) return;

    state = state.copyWith(isTranslating: true, error: null);
    try {
      final result = await _translator.translate(
        direction: state.direction,
        textInput: state.inputText.trim(),
      );
      state = state.copyWith(
        isTranslating: false,
        outputText: result.outputText,
        lastResult: result,
      );
    } catch (e) {
      state = state.copyWith(isTranslating: false, error: e.toString());
    }
  }

  Future<void> speakOutput() async {
    final text = state.outputText.trim();
    if (text.isEmpty) return;
    final isArabicOutput =
        state.direction == EslTranslationDirection.eslToArabic;
    await _speechIo.setTtsLanguage(isArabicOutput ? 'ar-SA' : 'en-US');
    await _speechIo.speak(text);
  }

  /// Speak arbitrary text in Arabic (used by ESL→AR camera mode).
  Future<void> speakArabic(String text) async {
    if (text.trim().isEmpty) return;
    await _speechIo.setTtsLanguage('ar-SA');
    await _speechIo.speak(text);
  }

  Future<void> startListening() async {
    if (state.isListening) return;
    state = state.copyWith(isListening: true, error: null);

    // AR→ESL: user speaks Arabic
    const localeId = 'ar_EG';

    try {
      await _speechIo.listen(
        onResult: (text) {
          state = state.copyWith(inputText: text);
        },
        source: state.audioSource,
        localeId: localeId,
      );
    } catch (e) {
      state = state.copyWith(isListening: false, error: e.toString());
    }
  }

  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _speechIo.stopListening();
    state = state.copyWith(isListening: false);
  }

  /// Toggle camera on/off for sign language detection.
  Future<void> toggleCamera() async {
    if (state.isCameraActive) {
      _signService.stopStreaming();
      state = state.copyWith(
        isCameraActive: false,
        handsDetected: false,
        faceDetected: false,
        lowLight: false,
        ambientBrightness: 0,
        framesCollected: 0,
        streamFps: 0,
      );
      return;
    }

    if (!state.hasCameraPermission) {
      state = state.copyWith(
        error: 'Camera permission is required for live sign translation.',
      );
      return;
    }

    if (!state.isModelReady) {
      final loaded = await _signService.loadModel();
      if (!loaded) {
        state = state.copyWith(
          error:
              'Unable to initialize the on-device sign model. '
              'Check assets/models and restart the app.',
        );
        return;
      }
    }

    try {
      await _signService.initCamera();
      await _signService.startStreaming();
      state = state.copyWith(
        isCameraActive: true,
        error: null,
        handsDetected: false,
        faceDetected: false,
        lowLight: false,
        ambientBrightness: 0,
        framesCollected: 0,
        framesNeeded: 30,
      );
    } catch (e) {
      state = state.copyWith(error: 'Camera error: $e', isCameraActive: false);
    }
  }

  void onSignDetected(String word) {
    final current = state.outputText;
    final updated = current.isEmpty ? word : '$current $word';
    state = state.copyWith(outputText: updated);
  }

  void clearDetection() {
    _signService.resetSession();
    state = state.copyWith(
      outputText: '',
      lastDetectedWord: '',
      detectionConfidence: 0.0,
      detectedSentence: '',
      framesCollected: 0,
      lowLight: false,
      ambientBrightness: 0,
    );
  }

  @override
  void dispose() {
    _signService.onPrediction = null;
    _signService.onStatus = null;
    _signService.onMetrics = null;
    _signService.onError = null;
    _signService.onConnectionChanged = null;
    _signService.onLabelsReceived = null;
    _speechIo.dispose();
    _signService.dispose();
    super.dispose();
  }
}

final _translatorProvider = Provider<EslTranslator>((ref) {
  return StubEslTranslator();
});

final _speechIoProvider = Provider<SpeechIoService>((ref) {
  final hw = ref.watch(hardwareServiceProvider);
  return SpeechIoService(hardwareService: hw);
});

final translatorControllerProvider =
    StateNotifierProvider<TranslatorController, TranslatorState>((ref) {
      final translator = ref.watch(_translatorProvider);
      final speechIo = ref.watch(_speechIoProvider);
      final signService = ref.watch(signLanguageServiceProvider);
      return TranslatorController(
        translator: translator,
        speechIo: speechIo,
        signService: signService,
      );
    });

final quickPhrasesProvider = Provider<List<QuickPhrase>>((ref) {
  return const [
    QuickPhrase(
      id: 'sos_help',
      label: 'SOS – I need help',
      text: 'أحتاج إلى مساعدة عاجلة',
      category: 'emergency',
    ),
    QuickPhrase(
      id: 'where_am_i',
      label: 'Where am I?',
      text: 'من فضلك، أين أنا؟',
      category: 'emergency',
    ),
    QuickPhrase(
      id: 'call_family',
      label: 'Call my family',
      text: 'من فضلك اتصل بعائلتي',
      category: 'emergency',
    ),
    QuickPhrase(
      id: 'thank_you',
      label: 'Thank you',
      text: 'شكرًا جزيلًا',
      category: 'daily',
    ),
    QuickPhrase(
      id: 'slow_down',
      label: 'Please speak slowly',
      text: 'من فضلك تحدث ببطء',
      category: 'daily',
    ),
  ];
});
