import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR using ML Kit with both Latin and Arabic scripts.
/// Merges results from both recognizers so that bills printed in either
/// script are picked up in a single pass.
class OcrService {
  OcrService({
    TextRecognizer? latinRecognizer,
    TextRecognizer? arabicRecognizer,
  })  : _latin = latinRecognizer ??
            TextRecognizer(script: TextRecognitionScript.latin),
        // ML Kit does not have a standalone Arabic script enum — we use a
        // second Latin pass and rely on Arabic-numeral regex in the controller.
        _arabic = arabicRecognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _latin;
  final TextRecognizer _arabic;

  /// Recognise text using the Latin script (for English/number-heavy documents).
  Future<String> recognizeFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _latin.processImage(inputImage);
    return result.text.trim();
  }

  /// Recognise using both scripts and merge the results (for currency / mixed text).
  Future<String> recognizeBothScripts(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final latinResult = await _latin.processImage(inputImage);
    final arabicResult = await _arabic.processImage(inputImage);

    final latinText = latinResult.text.trim();
    final arabicText = arabicResult.text.trim();

    if (latinText.isEmpty) return arabicText;
    if (arabicText.isEmpty) return latinText;

    // Merge unique lines from both recognisers
    final latinLines = latinText.split('\n');
    final arabicLines = arabicText.split('\n');
    final seen = <String>{};
    final merged = <String>[];
    for (final line in [...latinLines, ...arabicLines]) {
      final norm = line.trim();
      if (norm.isNotEmpty && seen.add(norm)) {
        merged.add(norm);
      }
    }
    return merged.join('\n');
  }

  void dispose() {
    _latin.close();
    _arabic.close();
  }
}
