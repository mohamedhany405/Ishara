/// Fine-grained object classifier built on a quantised MobileNetV3-Large
/// trained on ImageNet (1000 classes), giving "Pear" rather than "Fruit".
///
/// Place `assets/models/mobilenet_v3_large.tflite` and
/// `assets/models/imagenet_labels.txt` in the bundle; if either is missing,
/// the classifier reports `isReady=false` and the controller falls back to
/// google_mlkit_image_labeling.
library;

import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

class ImagenetPrediction {
  const ImagenetPrediction(this.label, this.confidence);
  final String label;
  final double confidence;
}

class ImagenetClassifier {
  ImagenetClassifier._(this._interpreter, this._labels);

  final Interpreter? _interpreter;
  final List<String> _labels;

  static ImagenetClassifier? _cached;

  static Future<ImagenetClassifier> create() async {
    if (_cached != null) return _cached!;
    Interpreter? interp;
    var labels = const <String>[];
    try {
      await rootBundle.load('assets/models/mobilenet_v3_large.tflite');
      interp = await Interpreter.fromAsset('assets/models/mobilenet_v3_large.tflite');
      final raw = await rootBundle.loadString('assets/models/imagenet_labels.txt');
      labels = raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    } catch (_) {
      interp = null;
      labels = const [];
    }
    return _cached = ImagenetClassifier._(interp, labels);
  }

  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  /// Returns the top-k human-readable predictions for a 224x224 RGB float32 input.
  /// Caller is responsible for preprocessing (we keep this class lean to avoid
  /// pulling heavy image deps into the production graph).
  List<ImagenetPrediction> topKFromLogits(List<double> logits, {int k = 3}) {
    if (_labels.isEmpty || logits.isEmpty) return const [];
    final indexed = List<MapEntry<int, double>>.generate(
      logits.length,
      (i) => MapEntry(i, logits[i]),
    )..sort((a, b) => b.value.compareTo(a.value));
    return indexed
        .take(k)
        .where((e) => e.key < _labels.length)
        .map((e) => ImagenetPrediction(_humanize(_labels[e.key]), e.value))
        .toList(growable: false);
  }

  static String _humanize(String raw) {
    // ImageNet class strings often look like "n02124075 Egyptian cat" — keep
    // only the human-readable suffix.
    final parts = raw.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts.first.startsWith('n')) {
      return parts.sublist(1).join(' ');
    }
    return raw;
  }
}
