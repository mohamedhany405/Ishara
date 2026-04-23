import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// On-device image labeling using ML Kit (default model).
class ImageLabelingService {
  ImageLabelingService({ImageLabeler? labeler})
    : _labeler =
          labeler ??
          ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));

  final ImageLabeler _labeler;

  /// Returns a list of (label, confidence) pairs sorted by confidence desc.
  Future<List<DetectedObject>> labelImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final labels = await _labeler.processImage(inputImage);
    final results =
        labels
            .map(
              (l) => DetectedObject(
                label: l.label,
                confidence: l.confidence,
                source: DetectionSource.imageLabel,
              ),
            )
            .toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  void dispose() {
    _labeler.close();
  }
}

enum DetectionSource { objectDetector, imageLabel, ocrCurrency, ocrText }

class DetectedObject {
  const DetectedObject({
    required this.label,
    required this.confidence,
    this.boundingBox,
    this.secondaryLabel,
    this.source = DetectionSource.imageLabel,
  });

  final String label;
  final double confidence;
  final Rect? boundingBox;
  final String? secondaryLabel;
  final DetectionSource source;

  DetectedObject copyWith({
    String? label,
    double? confidence,
    Rect? boundingBox,
    String? secondaryLabel,
    DetectionSource? source,
  }) {
    return DetectedObject(
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
      secondaryLabel: secondaryLabel ?? this.secondaryLabel,
      source: source ?? this.source,
    );
  }
}
