import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// On-device image labeling using ML Kit (default model).
class ImageLabelingService {
  ImageLabelingService({
    ImageLabeler? labeler,
  }) : _labeler = labeler ??
            ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));

  final ImageLabeler _labeler;

  /// Returns a list of (label, confidence) pairs sorted by confidence desc.
  Future<List<DetectedObject>> labelImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final labels = await _labeler.processImage(inputImage);
    final results = labels
        .map((l) => DetectedObject(label: l.label, confidence: l.confidence))
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  void dispose() {
    _labeler.close();
  }
}

class DetectedObject {
  const DetectedObject({required this.label, required this.confidence});
  final String label;
  final double confidence;
}
