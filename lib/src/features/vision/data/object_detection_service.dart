import 'dart:io';

import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    show InputImage;

import 'image_labeling_service.dart'; // our app-wide DetectedObject

/// Wraps ML Kit Object Detector for specific consumer-product detection.
/// Returns per-object labels as our app-wide [DetectedObject], useful for
/// headphones, bags, tissue boxes etc. that the general ImageNet labeler misses.
class ObjectDetectionService {
  ObjectDetectionService({mlkit.ObjectDetector? detector})
      : _detector = detector ??
            mlkit.ObjectDetector(
              options: mlkit.ObjectDetectorOptions(
                mode: mlkit.DetectionMode.single,
                classifyObjects: true,
                multipleObjects: true,
              ),
            );

  final mlkit.ObjectDetector _detector;

  /// Runs ML Kit object detection and returns results as [DetectedObject] list.
  Future<List<DetectedObject>> detectObjects(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final objects = await _detector.processImage(inputImage);

    final results = <DetectedObject>[];
    for (final obj in objects) {
      for (final label in obj.labels) {
        results.add(
          DetectedObject(
            label: label.text,
            confidence: label.confidence,
          ),
        );
      }
    }

    // Deduplicate by label, keep highest confidence
    final map = <String, DetectedObject>{};
    for (final r in results) {
      final key = r.label.toLowerCase();
      if (!map.containsKey(key) || map[key]!.confidence < r.confidence) {
        map[key] = r;
      }
    }

    final deduped = map.values.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return deduped;
  }

  void dispose() {
    _detector.close();
  }
}
