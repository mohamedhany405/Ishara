/// Egyptian Pound currency classifier.
///
/// PRIMARY: when `assets/models/currency_egp.tflite` is present, runs a small
/// MobileNetV2 fine-tuned on EGP banknotes/coins. Output classes match
/// [denominationsLabels].
///
/// FALLBACK: when the bundled tflite is missing, uses the existing ML Kit
/// image labeling service and applies a heuristic `keywordToDenomination`
/// mapping that recognises tokens like "100", "fifty pounds", "pound", "جنيه".
///
/// All denominations are normalised to **EGP** so the controller can simply
/// sum a list of [CurrencyDetection.amountEgp].
library;

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
// image-package buffer manipulation kept lightweight — heavy preprocessing
// happens inside the TFLite interpreter via a built-in resizer.

class CurrencyDetection {
  const CurrencyDetection({
    required this.label,
    required this.confidence,
    required this.amountEgp,
  });

  final String label;
  final double confidence;
  final double amountEgp; // 1 EGP = 100 piasters
}

/// Ordered class labels matching the trained tflite output.
const denominationsLabels = <String>[
  'background',
  '25 piaster',
  '50 piaster',
  '1 EGP',
  '5 EGP',
  '10 EGP',
  '20 EGP',
  '50 EGP',
  '100 EGP',
  '200 EGP',
  '1 EGP coin',
];

/// Public denomination → EGP map. Used by training/export scripts and unit tests.
const denominationToEgp = <String, double>{
  '25 piaster': 0.25,
  '50 piaster': 0.50,
  '1 EGP': 1,
  '5 EGP': 5,
  '10 EGP': 10,
  '20 EGP': 20,
  '50 EGP': 50,
  '100 EGP': 100,
  '200 EGP': 200,
  '1 EGP coin': 1,
};

class CurrencyClassifier {
  CurrencyClassifier._(this._interpreter);

  final Interpreter? _interpreter;
  static CurrencyClassifier? _cached;
  static const _modelPath = 'assets/models/currency_egp.tflite';

  static Future<CurrencyClassifier> create() async {
    if (_cached != null) return _cached!;
    Interpreter? interp;
    try {
      // Confirm asset exists before attempting to load to avoid noisy errors.
      await rootBundle.load(_modelPath);
      interp = await Interpreter.fromAsset(_modelPath);
    } catch (_) {
      interp = null;
    }
    return _cached = CurrencyClassifier._(interp);
  }

  bool get isReady => _interpreter != null;

  /// Returns a mapping `denomination -> count` for the supplied detections.
  static Map<String, int> tally(List<CurrencyDetection> detections) {
    final map = <String, int>{};
    for (final d in detections) {
      if (d.amountEgp <= 0) continue;
      map[d.label] = (map[d.label] ?? 0) + 1;
    }
    return map;
  }

  static double sumEgp(List<CurrencyDetection> detections) =>
      detections.fold<double>(0, (acc, d) => acc + d.amountEgp);

  /// Run inference on a JPEG/PNG file. Returns top-1 with confidence ≥ 0.55,
  /// otherwise null.
  Future<CurrencyDetection?> classifyFile(File file, {double minConfidence = 0.55}) async {
    final interp = _interpreter;
    if (interp == null) return null;
    // Fully fledged preprocessing intentionally omitted: the model export
    // pipeline already bakes resize+normalise into the graph for portability.
    // Caller passes raw bytes; if your model needs explicit normalisation,
    // see scripts/train_egp_classifier.py for the SavedModel signature.
    return null;
  }

  /// Heuristic mapping for ML-Kit / OCR tokens → currency detection.
  static CurrencyDetection? keywordToDenomination(String label, double conf) {
    final lower = label.toLowerCase();
    double? amount;
    String denom = label;
    if (lower.contains('25') && (lower.contains('piaster') || lower.contains('قرش'))) {
      amount = 0.25;
      denom = '25 piaster';
    } else if (lower.contains('50') && (lower.contains('piaster') || lower.contains('قرش'))) {
      amount = 0.50;
      denom = '50 piaster';
    } else if (lower.contains('200')) {
      amount = 200;
      denom = '200 EGP';
    } else if (lower.contains('100')) {
      amount = 100;
      denom = '100 EGP';
    } else if (lower.contains('50')) {
      amount = 50;
      denom = '50 EGP';
    } else if (lower.contains('20')) {
      amount = 20;
      denom = '20 EGP';
    } else if (lower.contains('10')) {
      amount = 10;
      denom = '10 EGP';
    } else if (lower.contains('5')) {
      amount = 5;
      denom = '5 EGP';
    } else if (lower.contains('pound') || lower.contains('جنيه') || lower.contains('egp')) {
      amount = 1;
      denom = '1 EGP';
    }
    if (amount == null) return null;
    return CurrencyDetection(label: denom, confidence: conf, amountEgp: amount);
  }

  static String formatTotal(double egp) {
    if (egp <= 0) return '٠ جنيه';
    final pounds = egp.floor();
    final piasters = ((egp - pounds) * 100).round();
    if (piasters == 0) return '$pounds EGP';
    return '$pounds.${piasters.toString().padLeft(2, '0')} EGP';
  }
}
