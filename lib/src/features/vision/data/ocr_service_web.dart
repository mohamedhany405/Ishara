import 'package:image_picker/image_picker.dart';

/// Web fallback: this app currently uses mobile ML Kit for OCR.
class OcrService {
  Future<String> recognizeFromFile(XFile imageFile) async {
    return 'OCR is not available on web yet. Please use Android or iOS build.';
  }

  Future<String> recognizeBothScripts(XFile imageFile) async {
    return recognizeFromFile(imageFile);
  }

  void dispose() {}
}
