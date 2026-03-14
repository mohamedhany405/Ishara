import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hardware/glasses_provider.dart';
import '../data/esl_translator_service.dart';
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
      );
}

class TranslatorController extends StateNotifier<TranslatorState> {
  TranslatorController({
    required EslTranslator translator,
    required SpeechIoService speechIo,
  })  : _translator = translator,
        _speechIo = speechIo,
        super(TranslatorState.initial());

  final EslTranslator _translator;
  final SpeechIoService _speechIo;

  void setInput(String text) {
    state = state.copyWith(inputText: text, error: null);
  }

  void setAudioSource(AudioSource source) {
    state = state.copyWith(audioSource: source);
  }

  void toggleDirection() {
    final next = state.direction == EslTranslationDirection.eslToArabic
        ? EslTranslationDirection.arabicToEsl
        : EslTranslationDirection.eslToArabic;
    state = state.copyWith(
      direction: next,
      inputText: '',
      outputText: '',
      error: null,
      isCameraActive: false,
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
      state = state.copyWith(
        isTranslating: false,
        error: e.toString(),
      );
    }
  }

  Future<void> speakOutput() async {
    final text = state.outputText.trim();
    if (text.isEmpty) return;
    // ESL→AR output is Arabic; AR→ESL output is English
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
      state = state.copyWith(
        isListening: false,
        error: e.toString(),
      );
    }
  }

  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _speechIo.stopListening();
    state = state.copyWith(isListening: false);
  }

  void toggleCamera() {
    state = state.copyWith(isCameraActive: !state.isCameraActive);
  }

  void onSignDetected(String word) {
    // Append detected sign word to output
    final current = state.outputText;
    final updated = current.isEmpty ? word : '$current $word';
    state = state.copyWith(outputText: updated);
  }

  @override
  void dispose() {
    _speechIo.dispose();
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
  return TranslatorController(translator: translator, speechIo: speechIo);
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

