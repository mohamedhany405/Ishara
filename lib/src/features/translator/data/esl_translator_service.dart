import 'dart:async';

import '../domain/esl_translation_models.dart';

/// Abstraction over the on-device ESL model so we can swap implementations.
abstract class EslTranslator {
  Future<EslTranslationResult> translate({
    required EslTranslationDirection direction,
    required String textInput,
  });
}

/// Placeholder implementation that will later call the V6 TFLite model.
class StubEslTranslator implements EslTranslator {
  @override
  Future<EslTranslationResult> translate({
    required EslTranslationDirection direction,
    required String textInput,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final pseudoOutput = switch (direction) {
      EslTranslationDirection.eslToArabic =>
        'ترجمة تجريبية لـ: $textInput',
      EslTranslationDirection.arabicToEsl =>
        'ESL(placeholder) for: $textInput',
    };

    return EslTranslationResult(
      direction: direction,
      inputText: textInput,
      outputText: pseudoOutput,
      confidence: 0.92,
      timestamp: DateTime.now(),
    );
  }
}

/// Future implementation sketch using TFLite from V6 export.
class TfliteEslTranslator implements EslTranslator {
  TfliteEslTranslator({
    required Object interpreter,
    required this.labels,
  }) : _interpreter = interpreter;

  final Object _interpreter;
  final List<String> labels;

  @override
  Future<EslTranslationResult> translate({
    required EslTranslationDirection direction,
    required String textInput,
  }) async {
    // Prevent unused field warning until model wiring is implemented.
    final _ = _interpreter;

    // TODO: feed preprocessed keypoint sequence from camera/mediapipe pipeline
    // into [1, T, F] tensor, then map argmax to labels.
    throw UnimplementedError('TfliteEslTranslator not wired yet.');
  }
}

