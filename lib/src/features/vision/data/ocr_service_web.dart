import 'package:image_picker/image_picker.dart';

class OcrTextBlock {
  const OcrTextBlock({
    required this.text,
    required this.rect,
    required this.confidence,
  });

  final String text;
  final dynamic rect;
  final double confidence;
}

class OcrDetailedResult {
  const OcrDetailedResult({required this.text, required this.blocks});

  final String text;
  final List<OcrTextBlock> blocks;
}

/// Web fallback: this app currently uses mobile ML Kit for OCR.
class OcrService {
  Future<String> recognizeFromFile(XFile imageFile) async {
    return 'OCR is not available on web yet. Please use Android or iOS build.';
  }

  Future<String> recognizeBothScripts(XFile imageFile) async {
    return recognizeFromFile(imageFile);
  }

  Future<OcrDetailedResult> recognizeDetailedFromFile(XFile imageFile) async {
    final text = await recognizeFromFile(imageFile);
    return OcrDetailedResult(text: text, blocks: const <OcrTextBlock>[]);
  }

  Future<OcrDetailedResult> recognizeDetailedBothScripts(
    XFile imageFile,
  ) async {
    final text = await recognizeBothScripts(imageFile);
    return OcrDetailedResult(text: text, blocks: const <OcrTextBlock>[]);
  }

  void dispose() {}
}
