import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_feedback.dart';
import '../data/image_labeling_service.dart';
import 'vision_controller.dart';

class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  CameraController? _cameraController;
  bool _isLiveCameraReady = false;
  bool _capturingLive = false;

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.mediumImpact();
    final xFile = await _picker.pickImage(source: source);
    if (xFile == null || !mounted) return;
    final bytes = await xFile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImage = xFile;
      _pickedImageBytes = bytes;
    });
    await ref.read(visionControllerProvider.notifier).processImage(xFile);
  }

  Future<void> _toggleLiveCamera() async {
    final ctrl = ref.read(visionControllerProvider.notifier);
    final state = ref.read(visionControllerProvider);
    if (state.liveMode) {
      await _stopLiveCamera();
      ctrl.setLiveMode(false);
      return;
    }

    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ctrl.setCameraPermission(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required for live vision mode.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ctrl.setCameraPermission(true);
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final live = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await live.initialize();
    await live.setFlashMode(FlashMode.off);

    if (!mounted) {
      await live.dispose();
      return;
    }

    setState(() {
      _cameraController = live;
      _isLiveCameraReady = true;
    });

    ctrl.setLiveMode(true);
    _startLiveLoop();
  }

  void _startLiveLoop() {
    Future<void>.microtask(() async {
      while (mounted && ref.read(visionControllerProvider).liveMode) {
        if (_cameraController == null ||
            !_cameraController!.value.isInitialized) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          continue;
        }

        if (_capturingLive || _cameraController!.value.isTakingPicture) {
          await Future<void>.delayed(const Duration(milliseconds: 160));
          continue;
        }

        try {
          _capturingLive = true;
          final frame = await _cameraController!.takePicture();
          await ref
              .read(visionControllerProvider.notifier)
              .processLiveFrame(frame);
        } catch (_) {
          // Ignore transient frame errors to keep stream alive.
        } finally {
          _capturingLive = false;
        }

        await Future<void>.delayed(const Duration(milliseconds: 220));
      }
    });
  }

  Future<void> _stopLiveCamera() async {
    final live = _cameraController;
    _cameraController = null;
    _isLiveCameraReady = false;
    if (live != null) {
      await live.dispose();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopLiveCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(visionControllerProvider);
    final ctrl = ref.read(visionControllerProvider.notifier);
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final hasResults =
        state.recognizedText.isNotEmpty ||
        state.currencySum.isNotEmpty ||
        state.currencyBreakdown.isNotEmpty ||
        state.objectDetections.isNotEmpty;
    final showIdleState =
        _pickedImageBytes == null &&
        !state.liveMode &&
        !state.isProcessing &&
        !hasResults;

    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Compact fixed header (no stretch) ──────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 12,
                16,
                14,
              ),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0D2137) : const Color(0xFFE8F5FF),
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark
                            ? IsharaColors.darkBorder
                            : IsharaColors.lightBorder,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback:
                              (b) => LinearGradient(
                                colors: [teal, orange],
                              ).createShader(
                                Rect.fromLTWH(0, 0, b.width, b.height),
                              ),
                          child: Text(
                            s.visionTitle,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.visionSub,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDark
                                    ? IsharaColors.mutedDark
                                    : IsharaColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.recognizedText.isNotEmpty ||
                      state.currencySum.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () {
                        ctrl.clearResult();
                        setState(() {
                          _pickedImage = null;
                          _pickedImageBytes = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Tool selector ──────────────────────────────────────
                _ToolSelector(
                      state: state,
                      ctrl: ctrl,
                      isDark: isDark,
                      teal: teal,
                    )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),

                const SizedBox(height: 16),

                // ── Camera / Gallery buttons ───────────────────────────
                Row(
                      children: [
                        Expanded(
                          child: _VisionActionButton(
                            label: state.isProcessing ? s.scanning : s.camera,
                            icon: Icons.camera_alt_rounded,
                            gradient: true,
                            loading: state.isProcessing,
                            isDark: isDark,
                            onTap:
                                state.isProcessing
                                    ? null
                                    : () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _VisionActionButton(
                            label: s.gallery,
                            icon: Icons.photo_library_rounded,
                            gradient: false,
                            isDark: isDark,
                            onTap:
                                state.isProcessing
                                    ? null
                                    : () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 350.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 100.ms,
                      duration: 300.ms,
                    ),

                const SizedBox(height: 12),

                _VisionActionButton(
                  label:
                      state.liveMode ? 'Stop Live Camera' : 'Start Live Camera',
                  icon:
                      state.liveMode
                          ? Icons.stop_rounded
                          : Icons.videocam_rounded,
                  gradient: false,
                  isDark: isDark,
                  onTap: _toggleLiveCamera,
                ).animate().fadeIn(delay: 130.ms, duration: 320.ms),

                if (showIdleState) ...[
                  const SizedBox(height: 14),
                  IsharaEmptyState(
                    icon: Icons.camera_enhance_outlined,
                    title: s.visionTitle,
                    message:
                        'Capture or pick an image to start on-device analysis.',
                    ctaLabel: s.camera,
                    onCtaTap: () => _pickImage(ImageSource.camera),
                  ).animate().fadeIn(delay: 160.ms, duration: 320.ms),
                ],

                if (state.liveMode) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: IsharaColors.cardRadius,
                      border: Border.all(color: teal.withOpacity(0.35)),
                    ),
                    child: ClipRRect(
                      borderRadius: IsharaColors.cardRadius,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_isLiveCameraReady && _cameraController != null)
                            CameraPreview(_cameraController!)
                          else
                            Container(
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          if (_isLiveCameraReady &&
                              _cameraController != null &&
                              state.overlayItems.isNotEmpty)
                            _VisionLiveOverlay(
                              items: state.overlayItems,
                              previewSize: _cameraController!.value.previewSize,
                              teal: teal,
                            ),

                          Positioned(
                            left: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Color(0xFF22C55E),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${state.lastFps.toStringAsFixed(1)} FPS • ${state.lastProcessingMs} ms',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (state.overlayMessage.isNotEmpty)
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  state.overlayMessage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  if (state.selectedTool == VisionTool.currency &&
                      state.currencySum.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: teal,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${state.currencySum} • confidence ${(state.lastCurrencyConfidence * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    isDark
                                        ? IsharaColors.mutedDark
                                        : IsharaColors.mutedLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // ── Error ──────────────────────────────────────────────
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.8),
                      borderRadius: IsharaColors.cardRadius,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).shakeX(duration: 400.ms),
                ],

                // ── Image preview ──────────────────────────────────────
                if (_pickedImageBytes != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                        borderRadius: IsharaColors.cardRadius,
                        child: Stack(
                          children: [
                            Image.memory(
                              _pickedImageBytes!,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            if (state.isProcessing)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: teal),
                                        const SizedBox(height: 12),
                                        Text(
                                          s.analysing,
                                          style: TextStyle(
                                            color: teal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                ],

                // ── Results ────────────────────────────────────────────
                if (state.recognizedText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ResultCard(
                        icon: Icons.text_fields_rounded,
                        label: s.recognizedText,
                        isDark: isDark,
                        teal: teal,
                        child: SelectableText(
                          state.recognizedText,
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 50.ms, duration: 400.ms)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        delay: 50.ms,
                        duration: 300.ms,
                      ),
                ],

                if (state.currencySum.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ResultCard(
                    icon: Icons.calculate_rounded,
                    label: s.currencyTotal,
                    isDark: isDark,
                    teal: teal,
                    child: Text(
                      state.currencySum,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        foreground:
                            Paint()
                              ..shader = LinearGradient(
                                colors: [teal, orange],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 200, 40),
                              ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                ],

                if (state.currencyBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ResultCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Denomination breakdown',
                    isDark: isDark,
                    teal: teal,
                    child: Text(
                      state.currencyBreakdown,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ).animate().fadeIn(delay: 120.ms, duration: 360.ms),
                ],

                if (state.objectDetections.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ResultCard(
                    icon: Icons.category_rounded,
                    label: 'Objects detected',
                    isDark: isDark,
                    teal: teal,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in state.objectDetections)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: teal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: teal.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${item.label} ${(item.confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: teal,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 130.ms, duration: 340.ms),
                ],

                if (state.spokenHistory.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ResultCard(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Spoken history',
                    isDark: isDark,
                    teal: teal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in state.spokenHistory)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: teal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${entry.text} • ${_formatHistoryTime(entry.timestamp)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 140.ms, duration: 340.ms),
                ],

                if (state.selectedTool == VisionTool.objects &&
                    _pickedImage == null) ...[
                  const SizedBox(height: 16),
                  _ResultCard(
                    icon: Icons.info_outline_rounded,
                    label: s.objectsMode,
                    isDark: isDark,
                    teal: teal,
                    child: Text(
                      s.objectsModeDesc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatHistoryTime(DateTime ts) {
  final hour = ts.hour.toString().padLeft(2, '0');
  final minute = ts.minute.toString().padLeft(2, '0');
  final second = ts.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

class _VisionLiveOverlay extends StatelessWidget {
  const _VisionLiveOverlay({
    required this.items,
    required this.previewSize,
    required this.teal,
  });

  final List<VisionOverlayItem> items;
  final Size? previewSize;
  final Color teal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewW = previewSize?.height ?? constraints.maxWidth;
        final previewH = previewSize?.width ?? constraints.maxHeight;
        final scaleX = constraints.maxWidth / (previewW <= 0 ? 1 : previewW);
        final scaleY = constraints.maxHeight / (previewH <= 0 ? 1 : previewH);

        return Stack(
          children: [
            for (final item in items)
              _buildOverlayBox(
                item: item,
                scaleX: scaleX,
                scaleY: scaleY,
                canvasW: constraints.maxWidth,
                canvasH: constraints.maxHeight,
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayBox({
    required VisionOverlayItem item,
    required double scaleX,
    required double scaleY,
    required double canvasW,
    required double canvasH,
  }) {
    final rect = item.rect;
    final mapped = Rect.fromLTWH(
      rect.left * scaleX,
      rect.top * scaleY,
      math.max(2, rect.width * scaleX),
      math.max(2, rect.height * scaleY),
    );

    final left =
        mapped.left.clamp(0.0, math.max(0.0, canvasW - 2.0)).toDouble();
    final top = mapped.top.clamp(0.0, math.max(0.0, canvasH - 2.0)).toDouble();
    final width =
        mapped.width.clamp(2.0, math.max(2.0, canvasW - left)).toDouble();
    final height =
        mapped.height.clamp(2.0, math.max(2.0, canvasH - top)).toDouble();

    final color = _sourceColor(item.source, teal);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.08),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.58),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.label} ${(item.confidence * 100).toStringAsFixed(0)}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _sourceColor(DetectionSource source, Color baseTeal) {
    switch (source) {
      case DetectionSource.objectDetector:
        return const Color(0xFF22C55E);
      case DetectionSource.imageLabel:
        return const Color(0xFF60A5FA);
      case DetectionSource.ocrCurrency:
        return const Color(0xFFF59E0B);
      case DetectionSource.ocrText:
        return baseTeal;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool selector: pill tabs for Currency / Read Text / Objects
// ─────────────────────────────────────────────────────────────────────────────
class _ToolSelector extends ConsumerWidget {
  const _ToolSelector({
    required this.state,
    required this.ctrl,
    required this.isDark,
    required this.teal,
  });
  final VisionState state;
  final VisionController ctrl;
  final bool isDark;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final tools = [
      (VisionTool.currency, Icons.money_rounded, s.currency),
      (VisionTool.readText, Icons.text_fields_rounded, s.readText),
      (VisionTool.objects, Icons.category_rounded, s.objects),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? IsharaColors.darkCard : IsharaColors.lightCard,
        borderRadius: IsharaColors.pillRadius,
        border: Border.all(
          color: isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
        ),
      ),
      child: Row(
        children:
            tools.map((e) {
              final (tool, icon, label) = e;
              final selected = state.selectedTool == tool;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ctrl.selectTool(tool);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: const BoxConstraints(
                      minHeight: IsharaColors.minTouchTarget,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? teal : Colors.transparent,
                      borderRadius: IsharaColors.pillRadius,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: selected ? Colors.white : teal,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _VisionActionButton extends StatelessWidget {
  const _VisionActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.isDark,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final IconData icon;
  final bool gradient;
  final bool isDark;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final disabled = onTap == null;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: IsharaColors.cardRadius,
        child: InkWell(
          borderRadius: IsharaColors.cardRadius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: IsharaColors.minTouchTarget,
            ),
            decoration: BoxDecoration(
              gradient:
                  gradient && !disabled
                      ? isharaHorizontalGradient(dark: isDark)
                      : null,
              color:
                  gradient
                      ? null
                      : (disabled
                          ? teal.withOpacity(0.08)
                          : Colors.transparent),
              borderRadius: IsharaColors.cardRadius,
              border:
                  gradient
                      ? null
                      : Border.all(
                        color: !disabled ? teal : teal.withOpacity(0.3),
                      ),
            ),
            child: Center(
              child:
                  loading
                      ? CircularProgressIndicator(
                        color: gradient ? Colors.white : teal,
                        strokeWidth: 2,
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color:
                                gradient
                                    ? Colors.white
                                    : (disabled
                                        ? theme.colorScheme.onSurface
                                            .withOpacity(0.45)
                                        : teal),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              color:
                                  gradient
                                      ? Colors.white
                                      : (disabled
                                          ? theme.colorScheme.onSurface
                                              .withOpacity(0.45)
                                          : teal),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.teal,
    required this.child,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final Color teal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassmorphismDecoration(dark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: teal),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: teal,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
