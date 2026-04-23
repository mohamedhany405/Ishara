import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/api/data_service.dart';
import '../data/image_labeling_service.dart';
import '../data/object_detection_service.dart';
import '../data/ocr_service.dart';

enum VisionTool { currency, readText, objects }

class VisionSpeechEntry {
  const VisionSpeechEntry({required this.text, required this.timestamp});

  final String text;
  final DateTime timestamp;
}

class VisionOverlayItem {
  const VisionOverlayItem({
    required this.label,
    required this.confidence,
    required this.rect,
    this.secondaryLabel,
    required this.source,
  });

  final String label;
  final double confidence;
  final Rect rect;
  final String? secondaryLabel;
  final DetectionSource source;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'confidence': confidence,
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
      'secondaryLabel': secondaryLabel,
      'source': source.name,
    };
  }
}

class VisionState {
  const VisionState({
    required this.selectedTool,
    required this.recognizedText,
    required this.currencySum,
    required this.currencyBreakdown,
    required this.objectDetections,
    required this.lastSpokenObject,
    required this.spokenHistory,
    required this.overlayItems,
    required this.liveMode,
    required this.hasCameraPermission,
    required this.overlayMessage,
    required this.lastFps,
    required this.lastProcessingMs,
    required this.lastCurrencyConfidence,
    required this.isProcessing,
    required this.error,
  });

  final VisionTool selectedTool;
  final String recognizedText;
  final String currencySum;
  final String currencyBreakdown;
  final List<DetectedObject> objectDetections;
  final String lastSpokenObject;
  final List<VisionSpeechEntry> spokenHistory;
  final List<VisionOverlayItem> overlayItems;
  final bool liveMode;
  final bool hasCameraPermission;
  final String overlayMessage;
  final double lastFps;
  final int lastProcessingMs;
  final double lastCurrencyConfidence;
  final bool isProcessing;
  final String? error;

  VisionState copyWith({
    VisionTool? selectedTool,
    String? recognizedText,
    String? currencySum,
    String? currencyBreakdown,
    List<DetectedObject>? objectDetections,
    String? lastSpokenObject,
    List<VisionSpeechEntry>? spokenHistory,
    List<VisionOverlayItem>? overlayItems,
    bool? liveMode,
    bool? hasCameraPermission,
    String? overlayMessage,
    double? lastFps,
    int? lastProcessingMs,
    double? lastCurrencyConfidence,
    bool? isProcessing,
    String? error,
  }) {
    return VisionState(
      selectedTool: selectedTool ?? this.selectedTool,
      recognizedText: recognizedText ?? this.recognizedText,
      currencySum: currencySum ?? this.currencySum,
      currencyBreakdown: currencyBreakdown ?? this.currencyBreakdown,
      objectDetections: objectDetections ?? this.objectDetections,
      lastSpokenObject: lastSpokenObject ?? this.lastSpokenObject,
      spokenHistory: spokenHistory ?? this.spokenHistory,
      overlayItems: overlayItems ?? this.overlayItems,
      liveMode: liveMode ?? this.liveMode,
      hasCameraPermission: hasCameraPermission ?? this.hasCameraPermission,
      overlayMessage: overlayMessage ?? this.overlayMessage,
      lastFps: lastFps ?? this.lastFps,
      lastProcessingMs: lastProcessingMs ?? this.lastProcessingMs,
      lastCurrencyConfidence:
          lastCurrencyConfidence ?? this.lastCurrencyConfidence,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }

  static VisionState get initial => const VisionState(
    selectedTool: VisionTool.readText,
    recognizedText: '',
    currencySum: '',
    currencyBreakdown: '',
    objectDetections: <DetectedObject>[],
    lastSpokenObject: '',
    spokenHistory: <VisionSpeechEntry>[],
    overlayItems: <VisionOverlayItem>[],
    liveMode: false,
    hasCameraPermission: false,
    overlayMessage: '',
    lastFps: 0,
    lastProcessingMs: 0,
    lastCurrencyConfidence: 0,
    isProcessing: false,
    error: null,
  );
}

class _CurrencyParseResult {
  const _CurrencyParseResult({
    required this.sumHeadline,
    required this.breakdown,
    required this.totalEgp,
    required this.confidence,
    required this.detectedValues,
  });

  final String sumHeadline;
  final String breakdown;
  final double totalEgp;
  final double confidence;
  final List<double> detectedValues;
}

class VisionController extends StateNotifier<VisionState> {
  VisionController({
    required OcrService ocrService,
    required ObjectDetectionService objectDetectionService,
    required ImageLabelingService imageLabelingService,
    required DataService dataService,
    FlutterTts? tts,
  }) : _ocr = ocrService,
       _objectDetector = objectDetectionService,
       _imageLabeler = imageLabelingService,
       _dataService = dataService,
       _tts = tts ?? FlutterTts(),
       super(VisionState.initial) {
    _configureTts();
  }

  final OcrService _ocr;
  final ObjectDetectionService _objectDetector;
  final ImageLabelingService _imageLabeler;
  final DataService _dataService;
  final FlutterTts _tts;

  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _fpsWindowStart = DateTime.now();
  int _processedInWindow = 0;

  static const Duration _liveThrottle = Duration(milliseconds: 250);

  void selectTool(VisionTool tool) {
    state = state.copyWith(selectedTool: tool, error: null, overlayItems: []);
  }

  void setLiveMode(bool value) {
    state = state.copyWith(liveMode: value, error: null);
  }

  void setCameraPermission(bool granted) {
    state = state.copyWith(hasCameraPermission: granted, error: null);
  }

  Future<void> processLiveFrame(XFile imageFile) async {
    if (!state.liveMode) return;
    if (state.isProcessing) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameAt) < _liveThrottle) {
      return;
    }

    _lastFrameAt = now;
    await processImage(imageFile, fromLiveCamera: true);
  }

  Future<void> processImage(
    XFile imageFile, {
    bool fromLiveCamera = false,
  }) async {
    final frameStart = DateTime.now();
    state = state.copyWith(isProcessing: true, error: null);

    try {
      if (state.selectedTool == VisionTool.currency) {
        await _processCurrency(imageFile);
      } else if (state.selectedTool == VisionTool.objects) {
        await _processObjects(imageFile);
      } else {
        await _processReadText(imageFile);
      }

      _recordFramePerformance(frameStart);

      if (fromLiveCamera) {
        await _cleanupLiveFrame(imageFile);
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
        overlayItems: const <VisionOverlayItem>[],
      );
    }
  }

  Future<void> _processCurrency(XFile imageFile) async {
    final detailed = await _ocr.recognizeDetailedBothScripts(imageFile);
    final parsed = _parseCurrencySum(detailed.text);

    final overlay = _buildCurrencyOverlay(
      detailed.blocks,
      parsed.detectedValues,
    );

    state = state.copyWith(
      isProcessing: false,
      recognizedText: detailed.text,
      currencySum: parsed.sumHeadline,
      currencyBreakdown: parsed.breakdown,
      overlayMessage: parsed.sumHeadline,
      objectDetections: const <DetectedObject>[],
      overlayItems: overlay,
      lastCurrencyConfidence: parsed.confidence,
    );

    await _persistVisionHistory(
      inputText: imageFile.path,
      outputText: parsed.sumHeadline,
      confidence: parsed.confidence,
      details: <String, dynamic>{
        'mode': 'currency',
        'rawText': detailed.text,
        'breakdown': parsed.breakdown,
        'total': parsed.totalEgp,
        'overlays': overlay.map((e) => e.toMap()).toList(),
      },
    );
  }

  Future<void> _processReadText(XFile imageFile) async {
    final detailed = await _ocr.recognizeDetailedFromFile(imageFile);

    final overlays =
        detailed.blocks
            .map(
              (b) => VisionOverlayItem(
                label:
                    b.text.length > 40
                        ? '${b.text.substring(0, 40)}...'
                        : b.text,
                confidence: b.confidence,
                rect: b.rect,
                source: DetectionSource.ocrText,
              ),
            )
            .toList();

    state = state.copyWith(
      isProcessing: false,
      recognizedText: detailed.text,
      currencySum: '',
      currencyBreakdown: '',
      objectDetections: const <DetectedObject>[],
      overlayMessage:
          detailed.text.isEmpty ? 'No text detected' : 'Text detected',
      overlayItems: overlays,
      lastCurrencyConfidence: 0,
    );

    await _persistVisionHistory(
      inputText: imageFile.path,
      outputText: detailed.text,
      confidence: _bestConfidenceFromText(detailed.text),
      details: <String, dynamic>{
        'mode': 'ocr',
        'textLength': detailed.text.length,
        'overlays': overlays.map((e) => e.toMap()).toList(),
      },
    );
  }

  Future<void> _processObjects(XFile imageFile) async {
    final file = File(imageFile.path);
    final objectResults = await _objectDetector.detectObjects(file);
    final labelResults = await _imageLabeler.labelImage(file);

    final merged = _mergeDetections(objectResults, labelResults);
    final topLabel = merged.isNotEmpty ? merged.first.label : '';

    final overlays =
        merged
            .where((d) => d.boundingBox != null)
            .map(
              (d) => VisionOverlayItem(
                label: d.label,
                confidence: d.confidence,
                rect: d.boundingBox!,
                secondaryLabel: d.secondaryLabel,
                source: d.source,
              ),
            )
            .toList();

    state = state.copyWith(
      isProcessing: false,
      recognizedText: '',
      currencySum: '',
      currencyBreakdown: '',
      objectDetections: merged,
      overlayMessage:
          topLabel.isNotEmpty ? 'Detected: $topLabel' : 'No objects detected',
      overlayItems: overlays,
      lastCurrencyConfidence: 0,
    );

    if (topLabel.isNotEmpty) {
      await _speakObject(topLabel);
    }

    await _persistVisionHistory(
      inputText: imageFile.path,
      outputText: topLabel.isNotEmpty ? topLabel : 'No objects detected',
      confidence: merged.isNotEmpty ? merged.first.confidence : 0,
      details: <String, dynamic>{
        'mode': 'objects',
        'objects':
            merged
                .map(
                  (d) => <String, dynamic>{
                    'label': d.label,
                    'confidence': d.confidence,
                    'source': d.source.name,
                    'left': d.boundingBox?.left,
                    'top': d.boundingBox?.top,
                    'right': d.boundingBox?.right,
                    'bottom': d.boundingBox?.bottom,
                  },
                )
                .toList(),
      },
    );
  }

  void _recordFramePerformance(DateTime frameStart) {
    final now = DateTime.now();
    final processingMs = now.difference(frameStart).inMilliseconds;

    _processedInWindow += 1;
    final elapsedWindowMs = now.difference(_fpsWindowStart).inMilliseconds;

    double fps = state.lastFps;
    if (elapsedWindowMs >= 1000) {
      fps = _processedInWindow / (elapsedWindowMs / 1000);
      _fpsWindowStart = now;
      _processedInWindow = 0;
    }

    state = state.copyWith(lastProcessingMs: processingMs, lastFps: fps);
  }

  Future<void> _cleanupLiveFrame(XFile imageFile) async {
    final p = imageFile.path;
    if (p.isEmpty) return;
    try {
      final file = File(p);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Keep live loop resilient against temp file cleanup failures.
    }
  }

  Future<void> _persistVisionHistory({
    required String inputText,
    required String outputText,
    required double confidence,
    required Map<String, dynamic> details,
  }) async {
    if (outputText.trim().isEmpty) return;

    try {
      await _dataService.addVisionHistory(
        inputText: inputText,
        outputText: outputText,
        confidence: confidence,
        details: details,
      );
    } catch (_) {
      // Ignore persistence failures for uninterrupted realtime vision.
    }
  }

  Future<void> _configureTts() async {
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
  }

  Future<void> _speakObject(String label) async {
    final now = DateTime.now();
    if (state.lastSpokenObject.toLowerCase() == label.toLowerCase() &&
        now.difference(_lastSpokenAt).inSeconds < 2) {
      return;
    }

    _lastSpokenAt = now;

    final arabic = _toArabicObjectLabel(label);
    final textToSpeak = arabic != null ? '$arabic - $label' : label;

    // Try Arabic first when translation exists, then fallback to English.
    if (arabic != null) {
      try {
        await _tts.setLanguage('ar-SA');
        await _tts.speak(arabic);
      } catch (_) {
        // Fallback below.
      }
    }

    try {
      await _tts.setLanguage('en-US');
      await _tts.speak(label);
    } catch (_) {
      // Keep state update even if platform TTS fails.
    }

    final history = <VisionSpeechEntry>[
      VisionSpeechEntry(text: textToSpeak, timestamp: now),
      ...state.spokenHistory,
    ];

    state = state.copyWith(
      lastSpokenObject: label,
      spokenHistory: history.take(8).toList(growable: false),
    );
  }

  String? _toArabicObjectLabel(String label) {
    final key = label.trim().toLowerCase();
    const dict = <String, String>{
      'person': 'شخص',
      'bottle': 'زجاجة',
      'cup': 'كوب',
      'book': 'كتاب',
      'cell phone': 'هاتف',
      'mobile phone': 'هاتف',
      'laptop': 'حاسوب محمول',
      'keyboard': 'لوحة مفاتيح',
      'mouse': 'فأرة',
      'chair': 'كرسي',
      'table': 'طاولة',
      'car': 'سيارة',
      'bus': 'حافلة',
      'dog': 'كلب',
      'cat': 'قطة',
      'banana': 'موز',
      'apple': 'تفاح',
      'orange': 'برتقال',
      'clock': 'ساعة',
      'tv': 'تلفاز',
    };
    return dict[key];
  }

  double _bestConfidenceFromText(String text) {
    if (text.trim().isEmpty) return 0;
    final density = text.trim().length / 60.0;
    return density.clamp(0.35, 0.98).toDouble();
  }

  _CurrencyParseResult _parseCurrencySum(String raw) {
    if (raw.trim().isEmpty) {
      return const _CurrencyParseResult(
        sumHeadline: 'No currency detected',
        breakdown: 'Point camera to EGP notes/coins',
        totalEgp: 0,
        confidence: 0,
        detectedValues: <double>[],
      );
    }

    final normalized = _normalizeArabicDigits(raw.toLowerCase());
    final hits = <double>[];

    final denominations = <double, int>{
      0.25: 0,
      0.5: 0,
      1: 0,
      5: 0,
      10: 0,
      20: 0,
      50: 0,
      100: 0,
      200: 0,
    };

    final patterns = <double, RegExp>{
      200: RegExp(r'(?:\b200\b|مائت(?:ان|ين)?|مئتين)'),
      100: RegExp(r'(?:\b100\b|مائ(?:ة|ه)|مية)'),
      50: RegExp(r'(?:\b50\b|خمس(?:ون|ين)|fifty)'),
      20: RegExp(r'(?:\b20\b|عشر(?:ون|ين)|twenty)'),
      10: RegExp(r'(?:\b10\b|عشر(?:ة|ه)|ten)'),
      5: RegExp(r'(?:\b5\b|خمس(?:ة|ه)|five)'),
      1: RegExp(r'(?:\b1\b|جنيه|pound)'),
      0.5: RegExp(r'(?:\b50\b\s*(?:piast|قرش)|نصف\s*جنيه)'),
      0.25: RegExp(r'(?:\b25\b\s*(?:piast|قرش)|ربع\s*جنيه)'),
    };

    for (final entry in patterns.entries) {
      final matches = entry.value.allMatches(normalized).length;
      if (matches > 0) {
        denominations[entry.key] = (denominations[entry.key] ?? 0) + matches;
        for (var i = 0; i < matches; i++) {
          hits.add(entry.key);
        }
      }
    }

    final numberMatches = RegExp(
      r'(?<!\d)(\d{1,3})(?!\d)',
    ).allMatches(normalized);
    for (final match in numberMatches) {
      final value = double.tryParse(match.group(1) ?? '');
      if (value == null || value > 200) continue;

      final start = math.max(0, match.start - 18);
      final end = math.min(normalized.length, match.end + 18);
      final near = normalized.substring(start, end);

      final isPiaster =
          near.contains('piast') ||
          near.contains('قرش') ||
          near.contains('piaster');
      if (isPiaster && (value == 25 || value == 50)) {
        final converted = value / 100;
        denominations[converted] = (denominations[converted] ?? 0) + 1;
        hits.add(converted);
      } else if (<int>[1, 5, 10, 20, 50, 100, 200].contains(value.toInt())) {
        final den = value.toInt().toDouble();
        denominations[den] = (denominations[den] ?? 0) + 1;
        hits.add(den);
      }
    }

    double total = 0;
    final lines = <String>[];

    for (final den in denominations.keys.toList()..sort()) {
      final count = denominations[den] ?? 0;
      if (count <= 0) continue;

      total += den * count;
      final label =
          den >= 1
              ? '${den.toStringAsFixed(den % 1 == 0 ? 0 : 2)} EGP'
              : '${(den * 100).toStringAsFixed(0)} piasters';
      lines.add('$label x$count');
    }

    if (total == 0) {
      return _CurrencyParseResult(
        sumHeadline: 'No currency value recognized',
        breakdown:
            'Detected text: ${raw.length > 120 ? '${raw.substring(0, 120)}...' : raw}',
        totalEgp: 0,
        confidence: 0.25,
        detectedValues: const <double>[],
      );
    }

    final confidence =
        (0.55 + (hits.length * 0.06)).clamp(0.55, 0.98).toDouble();

    return _CurrencyParseResult(
      sumHeadline: 'Total: ${total.toStringAsFixed(2)} EGP',
      breakdown: lines.join(' | '),
      totalEgp: total,
      confidence: confidence,
      detectedValues: hits,
    );
  }

  List<VisionOverlayItem> _buildCurrencyOverlay(
    List<OcrTextBlock> blocks,
    List<double> values,
  ) {
    if (blocks.isEmpty) return const <VisionOverlayItem>[];

    final overlays = <VisionOverlayItem>[];

    for (final b in blocks) {
      final normalized = _normalizeArabicDigits(b.text.toLowerCase());
      final matchedValue = _findDominantCurrencyValue(normalized, values);
      final label =
          matchedValue == null
              ? 'Text'
              : (matchedValue >= 1
                  ? '${matchedValue.toStringAsFixed(matchedValue % 1 == 0 ? 0 : 2)} EGP'
                  : '${(matchedValue * 100).toStringAsFixed(0)} Piasters');

      overlays.add(
        VisionOverlayItem(
          label: label,
          confidence: b.confidence,
          rect: b.rect,
          secondaryLabel: b.text,
          source: DetectionSource.ocrCurrency,
        ),
      );
    }

    return overlays;
  }

  double? _findDominantCurrencyValue(String text, List<double> values) {
    if (values.isEmpty) return null;

    for (final v in values) {
      final token =
          v >= 1
              ? v.toStringAsFixed(v % 1 == 0 ? 0 : 2)
              : (v * 100).toStringAsFixed(0);
      if (text.contains(token)) {
        return v;
      }
    }

    return values.first;
  }

  String _normalizeArabicDigits(String input) {
    const arabicIndic = <String, String>{
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    var out = input;
    arabicIndic.forEach((k, v) {
      out = out.replaceAll(k, v);
    });
    return out;
  }

  List<DetectedObject> _mergeDetections(
    List<DetectedObject> objectDetections,
    List<DetectedObject> labelDetections,
  ) {
    final map = <String, DetectedObject>{};

    for (final item in <DetectedObject>[
      ...objectDetections,
      ...labelDetections,
    ]) {
      final key = item.label.trim().toLowerCase();
      if (key.isEmpty) continue;

      final prev = map[key];
      if (prev == null || item.confidence > prev.confidence) {
        map[key] = item;
      }
    }

    final merged =
        map.values.toList()
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return merged.take(8).toList(growable: false);
  }

  void clearResult() {
    state = state.copyWith(
      recognizedText: '',
      currencySum: '',
      currencyBreakdown: '',
      objectDetections: const <DetectedObject>[],
      overlayMessage: '',
      overlayItems: const <VisionOverlayItem>[],
      lastSpokenObject: '',
      spokenHistory: const <VisionSpeechEntry>[],
      lastCurrencyConfidence: 0,
      error: null,
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _ocr.dispose();
    _objectDetector.dispose();
    _imageLabeler.dispose();
    super.dispose();
  }
}

final _ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});

final _objectDetectionServiceProvider = Provider<ObjectDetectionService>((ref) {
  return ObjectDetectionService();
});

final _imageLabelingServiceProvider = Provider<ImageLabelingService>((ref) {
  return ImageLabelingService();
});

final visionControllerProvider =
    StateNotifierProvider<VisionController, VisionState>((ref) {
      final ocr = ref.watch(_ocrServiceProvider);
      final objectDetector = ref.watch(_objectDetectionServiceProvider);
      final imageLabeler = ref.watch(_imageLabelingServiceProvider);
      final dataService = ref.watch(dataServiceProvider);

      return VisionController(
        ocrService: ocr,
        objectDetectionService: objectDetector,
        imageLabelingService: imageLabeler,
        dataService: dataService,
      );
    });
