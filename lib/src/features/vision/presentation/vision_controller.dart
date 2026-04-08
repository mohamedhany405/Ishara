import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/image_labeling_service.dart';
import '../data/object_detection_service.dart';
import '../data/ocr_service.dart';

enum VisionTool { currency, readText, objects }

class VisionState {
  const VisionState({
    required this.selectedTool,
    required this.recognizedText,
    required this.recognizedLines,
    required this.currencySum,
    required this.currencyBreakdown,
    required this.detectedItems,
    required this.isProcessing,
    required this.isSpeaking,
    required this.error,
  });

  final VisionTool selectedTool;
  final String recognizedText;
  final List<String> recognizedLines;
  final String currencySum;
  final List<String> currencyBreakdown;
  final List<DetectedObject> detectedItems;
  final bool isProcessing;
  final bool isSpeaking;
  final String? error;

  VisionState copyWith({
    VisionTool? selectedTool,
    String? recognizedText,
    List<String>? recognizedLines,
    String? currencySum,
    List<String>? currencyBreakdown,
    List<DetectedObject>? detectedItems,
    bool? isProcessing,
    bool? isSpeaking,
    String? error,
  }) {
    return VisionState(
      selectedTool: selectedTool ?? this.selectedTool,
      recognizedText: recognizedText ?? this.recognizedText,
      recognizedLines: recognizedLines ?? this.recognizedLines,
      currencySum: currencySum ?? this.currencySum,
      currencyBreakdown: currencyBreakdown ?? this.currencyBreakdown,
      detectedItems: detectedItems ?? this.detectedItems,
      isProcessing: isProcessing ?? this.isProcessing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: error,
    );
  }

  bool get hasResult =>
      recognizedText.isNotEmpty ||
      currencySum.isNotEmpty ||
      detectedItems.isNotEmpty;

  static VisionState get initial => const VisionState(
        selectedTool: VisionTool.readText,
        recognizedText: '',
        recognizedLines: [],
        currencySum: '',
        currencyBreakdown: [],
        detectedItems: [],
        isProcessing: false,
        isSpeaking: false,
        error: null,
      );
}

class VisionController extends StateNotifier<VisionState> {
  VisionController({
    required OcrService ocrService,
    required ImageLabelingService labelingService,
    required ObjectDetectionService detectionService,
    FlutterTts? tts,
  })  : _ocr = ocrService,
        _labeler = labelingService,
        _detector = detectionService,
        _tts = tts ?? FlutterTts(),
        super(VisionState.initial) {
    _initTts();
  }

  final OcrService _ocr;
  final ImageLabelingService _labeler;
  final ObjectDetectionService _detector;
  final FlutterTts _tts;

  Future<void> _initTts() async {
    await _tts.setLanguage('ar-EG');
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) state = state.copyWith(isSpeaking: false);
    });
    _tts.setCancelHandler(() {
      if (mounted) state = state.copyWith(isSpeaking: false);
    });
  }

  void selectTool(VisionTool tool) {
    state = state.copyWith(selectedTool: tool, error: null);
  }

  Future<void> processImage(File imageFile) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      switch (state.selectedTool) {
        case VisionTool.currency:
          final text = await _ocr.recognizeBothScripts(imageFile);
          final parsed = _parseEgyptianCurrency(text);
          state = state.copyWith(
            isProcessing: false,
            recognizedText: text,
            currencySum: parsed.total,
            currencyBreakdown: parsed.breakdown,
          );
          break;

        case VisionTool.readText:
          final text = await _ocr.recognizeFromFile(imageFile);
          final lines = _formatTextLines(text);
          state = state.copyWith(
            isProcessing: false,
            recognizedText: text,
            recognizedLines: lines,
          );
          break;

        case VisionTool.objects:
          // Run both labeler and object detector in parallel
          final labelFuture = _labeler.labelImage(imageFile);
          final detectFuture = _detector.detectObjects(imageFile);
          final labelItems = await labelFuture;
          final detectItems = await detectFuture;

          // Merge: object detector first (more specific), then fill from labeler
          final map = <String, DetectedObject>{};
          for (final item in [...detectItems, ...labelItems]) {
            final key = item.label.toLowerCase();
            if (!map.containsKey(key) ||
                map[key]!.confidence < item.confidence) {
              map[key] = item;
            }
          }
          final merged = map.values.toList()
            ..sort((a, b) => b.confidence.compareTo(a.confidence));

          state = state.copyWith(
            isProcessing: false,
            detectedItems: merged,
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  // ── Text line formatting ─────────────────────────────────────────────────────
  /// Splits OCR text into structured lines, detecting paragraphs and indents.
  List<String> _formatTextLines(String raw) {
    if (raw.trim().isEmpty) return [];
    final lines = raw.split('\n');
    final result = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Empty lines signal paragraph breaks — keep one empty entry as spacer
      if (line.trim().isEmpty) {
        if (result.isNotEmpty && result.last != '') result.add('');
        continue;
      }
      result.add(line);
    }
    // Remove trailing empty spacer
    while (result.isNotEmpty && result.last == '') {
      result.removeLast();
    }
    return result;
  }

  // ── Egyptian currency recognition ─────────────────────────────────────────────
  /// Denomination pattern groups. Each entry: (regex, egpValue, isPiastre)
  static final List<_DenomPattern> _denomPatterns = [
    // ── 200 EGP ──
    _DenomPattern(RegExp(r'٢٠٠|مائتا[نم]?|مائتين'), 200, false),
    _DenomPattern(RegExp(r'\b200\b'), 200, false),
    // ── 100 EGP ──
    _DenomPattern(RegExp(r'١٠٠|مائة|مئة'), 100, false),
    _DenomPattern(RegExp(r'\b100\b'), 100, false),
    // ── 50 EGP ──
    _DenomPattern(RegExp(r'٥٠|خمسون|خمسين'), 50, false),
    _DenomPattern(RegExp(r'\b50\b'), 50, false),
    // ── 20 EGP ──
    _DenomPattern(RegExp(r'٢٠|عشرون|عشرين'), 20, false),
    _DenomPattern(RegExp(r'\b20\b'), 20, false),
    // ── 10 EGP ──
    _DenomPattern(RegExp(r'١٠|عشر[ة]?'), 10, false),
    _DenomPattern(RegExp(r'\b10\b'), 10, false),
    // ── 5 EGP ──
    _DenomPattern(RegExp(r'٥|خمسة'), 5, false),
    _DenomPattern(RegExp(r'\b5\b'), 5, false),
    // ── 1 EGP (coin/note) ──
    _DenomPattern(RegExp(r'(?<![٢2])١(?![٠٠0])'), 1, false),
    _DenomPattern(RegExp(r'(?<!\d)1(?!\d)'), 1, false),
    // ── 2 EGP (coin) ──
    _DenomPattern(RegExp(r'(?<![١1])٢(?![٠0])'), 2, false),
    _DenomPattern(RegExp(r'(?<!\d)2(?!\d)'), 2, false),
    // ── 50 Piastres ──
    _DenomPattern(RegExp(r'٥٠\s*(قرش|pt|piastre)', caseSensitive: false), 0.5, true),
    _DenomPattern(RegExp(r'\b50\s*(قرش|pt|piastre)', caseSensitive: false), 0.5, true),
    // ── 25 Piastres ──
    _DenomPattern(RegExp(r'٢٥\s*(قرش|pt|piastre)', caseSensitive: false), 0.25, true),
    _DenomPattern(RegExp(r'\b25\s*(قرش|pt|piastre)', caseSensitive: false), 0.25, true),
  ];

  /// Piastre indicators in text — if found near a number, treat as subunit
  static final _piastreContext =
      RegExp(r'قرش|piastre|millime|مليم', caseSensitive: false);
  static final _egpContext =
      RegExp(r'جنيه|pound|egp|مصر|egypt|بنك|bank', caseSensitive: false);

  _CurrencyParseResult _parseEgyptianCurrency(String raw) {
    if (raw.trim().isEmpty) {
      return const _CurrencyParseResult(
          total: 'لم يتم اكتشاف نص – حاول بصورة أوضح', breakdown: []);
    }

    final hasCurrencyContext =
        _egpContext.hasMatch(raw) || _piastreContext.hasMatch(raw);

    final List<String> breakdown = [];
    double total = 0;

    for (final denom in _denomPatterns) {
      // Skip piastre patterns when there's no piastre context at all
      if (denom.isPiastre && !_piastreContext.hasMatch(raw)) continue;

      final matches = denom.pattern.allMatches(raw);
      for (final _ in matches) {
        total += denom.value;
        if (denom.isPiastre) {
          breakdown.add('${(denom.value * 100).toInt()} قرش');
        } else {
          breakdown.add('${denom.value.toInt()} جنيه');
        }
      }
    }

    // If no structured match, fall back to raw number extraction (when EGP context exists)
    if (total == 0 && hasCurrencyContext) {
      final numbers = RegExp(r'[\d.,٠-٩]+').allMatches(raw);
      for (final m in numbers) {
        var s = m.group(0)!;
        // Convert Arabic-Indic numerals
        s = _arabicNumeralsToWestern(s);
        final v = double.tryParse(s.replaceAll(',', ''));
        if (v != null && v > 0 && v <= 1000) {
          total += v;
          breakdown.add('${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)} EGP');
        }
      }
    }

    if (total > 0) {
      final totalStr = total == total.roundToDouble()
          ? '${total.toInt()} جنيه مصري'
          : '${total.toStringAsFixed(2)} جنيه مصري';
      return _CurrencyParseResult(
        total: 'الإجمالي: $totalStr',
        breakdown: breakdown,
      );
    }

    return const _CurrencyParseResult(
      total: 'لم يتم التعرف على عملة مصرية',
      breakdown: [],
    );
  }

  /// Converts Arabic-Indic digit string to Western digits
  static String _arabicNumeralsToWestern(String s) {
    const ar = '٠١٢٣٤٥٦٧٨٩';
    const en = '0123456789';
    var result = s;
    for (var i = 0; i < ar.length; i++) {
      result = result.replaceAll(ar[i], en[i]);
    }
    return result;
  }

  // ── TTS ────────────────────────────────────────────────────────────────────
  Future<void> speakResult() async {
    final text = _buildSpeakText();
    if (text.isEmpty) return;

    if (state.isSpeaking) {
      await _tts.stop();
      state = state.copyWith(isSpeaking: false);
      return;
    }

    state = state.copyWith(isSpeaking: true);

    // Use Arabic for Arabic text, English otherwise
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    await _tts.setLanguage(hasArabic ? 'ar-EG' : 'en-US');
    await _tts.speak(text);
  }

  String _buildSpeakText() {
    switch (state.selectedTool) {
      case VisionTool.currency:
        if (state.currencySum.isEmpty) return '';
        final breakdown = state.currencyBreakdown.join('، ');
        return '${state.currencySum}. التفاصيل: $breakdown';
      case VisionTool.readText:
        return state.recognizedText;
      case VisionTool.objects:
        if (state.detectedItems.isEmpty) return '';
        final labels = state.detectedItems.take(8).map((e) => e.label).join('، ');
        return 'الأشياء المكتشفة: $labels';
    }
  }

  void clearResult() {
    _tts.stop();
    state = state.copyWith(
      recognizedText: '',
      recognizedLines: [],
      currencySum: '',
      currencyBreakdown: [],
      detectedItems: [],
      isSpeaking: false,
      error: null,
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

// ── Internal helpers ──────────────────────────────────────────────────────────
class _DenomPattern {
  const _DenomPattern(this.pattern, this.value, this.isPiastre);
  final RegExp pattern;
  final double value;
  final bool isPiastre;
}

class _CurrencyParseResult {
  const _CurrencyParseResult({required this.total, required this.breakdown});
  final String total;
  final List<String> breakdown;
}

// ── Providers ─────────────────────────────────────────────────────────────────
final _ocrServiceProvider = Provider<OcrService>((ref) {
  final ocr = OcrService();
  ref.onDispose(() => ocr.dispose());
  return ocr;
});

final _imageLabelingServiceProvider = Provider<ImageLabelingService>((ref) {
  final labeler = ImageLabelingService();
  ref.onDispose(() => labeler.dispose());
  return labeler;
});

final _objectDetectionServiceProvider = Provider<ObjectDetectionService>((ref) {
  final detector = ObjectDetectionService();
  ref.onDispose(() => detector.dispose());
  return detector;
});

final visionControllerProvider =
    StateNotifierProvider<VisionController, VisionState>((ref) {
  final ocr = ref.watch(_ocrServiceProvider);
  final labeler = ref.watch(_imageLabelingServiceProvider);
  final detector = ref.watch(_objectDetectionServiceProvider);
  return VisionController(
    ocrService: ocr,
    labelingService: labeler,
    detectionService: detector,
  );
});
