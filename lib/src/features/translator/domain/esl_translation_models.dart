import 'package:equatable/equatable.dart';

enum EslTranslationDirection {
  eslToArabic,
  arabicToEsl,
}

class EslTranslationResult extends Equatable {
  const EslTranslationResult({
    required this.direction,
    required this.inputText,
    required this.outputText,
    required this.confidence,
    required this.timestamp,
  });

  final EslTranslationDirection direction;
  final String inputText;
  final String outputText;
  final double confidence;
  final DateTime timestamp;

  @override
  List<Object?> get props => [
        direction,
        inputText,
        outputText,
        confidence,
        timestamp,
      ];
}

class QuickPhrase extends Equatable {
  const QuickPhrase({
    required this.id,
    required this.label,
    required this.text,
    required this.category,
  });

  final String id;
  final String label;
  final String text;
  final String category; // e.g. "emergency", "daily", "travel"

  @override
  List<Object?> get props => [id, label, text, category];
}

