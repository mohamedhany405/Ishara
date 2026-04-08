import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ocr_service.dart';

enum VisionTool { currency, readText, objects }

class VisionState {
  const VisionState({
    required this.selectedTool,
    required this.recognizedText,
    required this.currencySum,
    required this.isProcessing,
    required this.error,
  });

  final VisionTool selectedTool;
  final String recognizedText;
  final String currencySum;
  final bool isProcessing;
  final String? error;

  VisionState copyWith({
    VisionTool? selectedTool,
    String? recognizedText,
    String? currencySum,
    bool? isProcessing,
    String? error,
  }) {
    return VisionState(
      selectedTool: selectedTool ?? this.selectedTool,
      recognizedText: recognizedText ?? this.recognizedText,
      currencySum: currencySum ?? this.currencySum,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }

  static VisionState get initial => const VisionState(
        selectedTool: VisionTool.readText,
        recognizedText: '',
        currencySum: '',
        isProcessing: false,
        error: null,
      );
}

class VisionController extends StateNotifier<VisionState> {
  VisionController({required OcrService ocrService})
      : _ocr = ocrService,
        super(VisionState.initial);

  final OcrService _ocr;

  void selectTool(VisionTool tool) {
    state = state.copyWith(selectedTool: tool, error: null);
  }

  Future<void> processImage(File imageFile) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final text = await _ocr.recognizeFromFile(imageFile);
      if (state.selectedTool == VisionTool.currency) {
        final sum = _parseCurrencySum(text);
        state = state.copyWith(
          isProcessing: false,
          recognizedText: text,
          currencySum: sum,
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          recognizedText: text,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  String _parseCurrencySum(String raw) {
    final numbers = RegExp(r'[\d.,]+').allMatches(raw);
    if (numbers.isEmpty) return raw.isNotEmpty ? raw : 'No numbers found';
    double total = 0;
    for (final m in numbers) {
      final s = m.group(0)!.replaceAll(',', '');
      total += double.tryParse(s) ?? 0;
    }
    return total > 0 ? 'Total: ${total.toStringAsFixed(2)} EGP' : raw;
  }

  void clearResult() {
    state = state.copyWith(
      recognizedText: '',
      currencySum: '',
      error: null,
    );
  }
}

final _ocrServiceProvider = Provider<OcrService>((ref) {
  final ocr = OcrService();
  ref.onDispose(() => ocr.dispose());
  return ocr;
});

final visionControllerProvider =
    StateNotifierProvider<VisionController, VisionState>((ref) {
  final ocr = ref.watch(_ocrServiceProvider);
  return VisionController(ocrService: ocr);
});
