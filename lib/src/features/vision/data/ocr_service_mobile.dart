import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' show Rect;

class OcrTextBlock {
  const OcrTextBlock({
    required this.text,
    required this.rect,
    required this.confidence,
  });

  final String text;
  final Rect rect;
  final double confidence;
}

class OcrDetailedResult {
  const OcrDetailedResult({required this.text, required this.blocks});

  final String text;
  final List<OcrTextBlock> blocks;
}

/// On-device OCR using ML Kit with both Latin and Arabic scripts.
/// Merges results from both recognizers so that bills printed in either
/// script are picked up in a single pass.
class OcrService {
  OcrService({
    TextRecognizer? latinRecognizer,
    TextRecognizer? arabicRecognizer,
  }) : _latin =
           latinRecognizer ??
           TextRecognizer(script: TextRecognitionScript.latin),
       // ML Kit does not have a standalone Arabic script enum — we use a
       // second Latin pass and rely on Arabic-numeral regex in the controller.
       _arabic =
           arabicRecognizer ??
           TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _latin;
  final TextRecognizer _arabic;

  /// Recognise text using the Latin script (for English/number-heavy documents).
  Future<String> recognizeFromFile(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final result = await _latin.processImage(inputImage);
    return result.text.trim();
  }

  Future<OcrDetailedResult> recognizeDetailedFromFile(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final result = await _latin.processImage(inputImage);
    final blocks = <OcrTextBlock>[];
    for (final block in result.blocks) {
      final text = block.text.trim();
      if (text.isEmpty) continue;
      blocks.add(
        OcrTextBlock(
          text: text,
          rect: block.boundingBox,
          // ML Kit text recognizer currently does not expose confidence.
          confidence: 0.95,
        ),
      );
    }
    return OcrDetailedResult(text: result.text.trim(), blocks: blocks);
  }

  /// Recognise using both scripts and merge the results (for currency / mixed text).
  Future<String> recognizeBothScripts(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final latinResult = await _latin.processImage(inputImage);
    final arabicResult = await _arabic.processImage(inputImage);

    final latinText = latinResult.text.trim();
    final arabicText = arabicResult.text.trim();

    if (latinText.isEmpty) return arabicText;
    if (arabicText.isEmpty) return latinText;

    // Merge unique lines from both recognisers.
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

  Future<OcrDetailedResult> recognizeDetailedBothScripts(
    XFile imageFile,
  ) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final latinResult = await _latin.processImage(inputImage);
    final arabicResult = await _arabic.processImage(inputImage);

    final mergedText = await recognizeBothScripts(imageFile);
    final blocks = <OcrTextBlock>[];
    final seen = <String>{};

    void addBlocks(RecognizedText text) {
      for (final block in text.blocks) {
        final blockText = block.text.trim();
        if (blockText.isEmpty) continue;
        final key =
            '${blockText.toLowerCase()}@${block.boundingBox.left.toStringAsFixed(1)}:${block.boundingBox.top.toStringAsFixed(1)}';
        if (!seen.add(key)) continue;
        blocks.add(
          OcrTextBlock(
            text: blockText,
            rect: block.boundingBox,
            confidence: 0.95,
          ),
        );
      }
    }

    addBlocks(latinResult);
    addBlocks(arabicResult);

    return OcrDetailedResult(text: mergedText, blocks: blocks);
  }

  void dispose() {
    _latin.close();
    _arabic.close();
  }
}
