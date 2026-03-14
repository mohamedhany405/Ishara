import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR using ML Kit. Latin script only (Arabic not in ML Kit v2 script enum).
class OcrService {
  OcrService({
    TextRecognizer? textRecognizer,
  }) : _recognizer = textRecognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<String> recognizeFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(inputImage);
    return result.text.trim();
  }

  void dispose() {
    _recognizer.close();
  }
}
