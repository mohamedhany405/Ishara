import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../data/image_labeling_service.dart';
import 'vision_controller.dart';

class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.mediumImpact();
    final xFile = await _picker.pickImage(source: source);
    if (xFile == null || !mounted) return;
    setState(() => _pickedImage = File(xFile.path));
    await ref
        .read(visionControllerProvider.notifier)
        .processImage(File(xFile.path));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(visionControllerProvider);
    final ctrl = ref.read(visionControllerProvider.notifier);
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Compact fixed header ────────────────────────────────────
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
                    color: isDark
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
                        // Use foreground paint instead of ShaderMask to prevent clipping
                        Text(
                          s.visionTitle,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.1,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [teal, orange],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 200, 40),
                              ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.visionSub,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Clear / reset button
                  if (state.hasResult)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () {
                        ctrl.clearResult();
                        setState(() => _pickedImage = null);
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
                _ToolSelector(state: state, ctrl: ctrl, isDark: isDark, teal: teal)
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
                        onTap: state.isProcessing
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
                        onTap: state.isProcessing
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

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
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).shakeX(duration: 400.ms),
                ],

                // ── Image preview ──────────────────────────────────────
                if (_pickedImage != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: IsharaColors.cardRadius,
                    child: Stack(
                      children: [
                        Image.file(
                          _pickedImage!,
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
                  ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                ],

                // ── Read Text Results ─────────────────────────────────
                if (state.selectedTool == VisionTool.readText &&
                    state.recognizedLines.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ReadTextResultCard(
                    lines: state.recognizedLines,
                    rawText: state.recognizedText,
                    isSpeaking: state.isSpeaking,
                    isDark: isDark,
                    teal: teal,
                    orange: orange,
                    theme: theme,
                    onSpeak: ctrl.speakResult,
                  ).animate().fadeIn(delay: 50.ms, duration: 400.ms),
                ],

                // ── Currency Results ──────────────────────────────────
                if (state.selectedTool == VisionTool.currency &&
                    state.currencySum.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _CurrencyResultCard(
                    total: state.currencySum,
                    breakdown: state.currencyBreakdown,
                    isSpeaking: state.isSpeaking,
                    isDark: isDark,
                    teal: teal,
                    orange: orange,
                    theme: theme,
                    onSpeak: ctrl.speakResult,
                  ).animate().fadeIn(delay: 50.ms, duration: 400.ms),
                ],

                // ── Object Results ────────────────────────────────────
                if (state.selectedTool == VisionTool.objects &&
                    state.detectedItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ObjectsResultCard(
                    items: state.detectedItems,
                    isSpeaking: state.isSpeaking,
                    isDark: isDark,
                    teal: teal,
                    theme: theme,
                    onSpeak: ctrl.speakResult,
                  ).animate().fadeIn(delay: 50.ms, duration: 400.ms),
                ],

                // ── Objects placeholder ───────────────────────────────
                if (state.selectedTool == VisionTool.objects &&
                    _pickedImage == null &&
                    state.detectedItems.isEmpty) ...[
                  const SizedBox(height: 16),
                  _PlaceholderCard(
                    icon: Icons.category_rounded,
                    label: s.objectsMode,
                    body: s.objectsModeDesc,
                    isDark: isDark,
                    teal: teal,
                    theme: theme,
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

// ─── Tool selector ────────────────────────────────────────────────────────────
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
        children: tools.map((e) {
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
                height: 38,
                decoration: BoxDecoration(
                  color: selected ? teal : Colors.transparent,
                  borderRadius: IsharaColors.pillRadius,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 15, color: selected ? Colors.white : teal),
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

// ─── TTS Speak Button ─────────────────────────────────────────────────────────
class _SpeakButton extends StatelessWidget {
  const _SpeakButton({
    required this.isSpeaking,
    required this.teal,
    required this.isDark,
    required this.onTap,
  });
  final bool isSpeaking;
  final Color teal;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSpeaking ? teal : teal.withOpacity(0.1),
          borderRadius: IsharaColors.pillRadius,
          border: Border.all(
            color: isSpeaking ? teal : teal.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
              size: 16,
              color: isSpeaking ? Colors.white : teal,
            ),
            const SizedBox(width: 6),
            Text(
              isSpeaking ? 'إيقاف' : 'استمع',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSpeaking ? Colors.white : teal,
              ),
            ),
            if (isSpeaking) ...[
              const SizedBox(width: 6),
              _WaveformIcon(color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

class _WaveformIcon extends StatelessWidget {
  const _WaveformIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 3,
          height: (4 + i * 3).toDouble(),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleY(
              begin: 0.5,
              end: 1,
              delay: Duration(milliseconds: 80 * i),
              duration: 400.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}

// ─── Read Text – formatted line-by-line card ──────────────────────────────────
class _ReadTextResultCard extends ConsumerWidget {
  const _ReadTextResultCard({
    required this.lines,
    required this.rawText,
    required this.isSpeaking,
    required this.isDark,
    required this.teal,
    required this.orange,
    required this.theme,
    required this.onSpeak,
  });
  final List<String> lines;
  final String rawText;
  final bool isSpeaking;
  final bool isDark;
  final Color teal, orange;
  final ThemeData theme;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassmorphismDecoration(dark: isDark).copyWith(
        border: Border.all(color: teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.text_fields_rounded, size: 16, color: teal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.recognizedText,
                  style: TextStyle(
                    color: teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              // Speak button
              _SpeakButton(
                isSpeaking: isSpeaking,
                teal: teal,
                isDark: isDark,
                onTap: onSpeak,
              ),
              const SizedBox(width: 8),
              // Copy button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: rawText));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.copied),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        backgroundColor: teal,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: teal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: teal.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: teal),
                        const SizedBox(width: 4),
                        Text(
                          s.copyText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Gradient divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  teal.withOpacity(0.3),
                  orange.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Lines list
          ...lines.asMap().entries.map((entry) {
            final i = entry.key;
            final line = entry.value;

            if (line.isEmpty) {
              // Paragraph spacer
              return const SizedBox(height: 12);
            }

            // Detect indentation
            final isIndented = line.startsWith('  ') || line.startsWith('\t');
            final trimmed = line.trimLeft();

            return Padding(
              padding: EdgeInsets.only(
                left: isIndented ? 20 : 0,
                bottom: 6,
              ),
              child: SelectableText(
                trimmed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.55,
                  letterSpacing: 0.1,
                ),
              ),
            ).animate().fadeIn(
                  delay: Duration(milliseconds: 20 * i),
                  duration: 200.ms,
                );
          }),
        ],
      ),
    );
  }
}

// ─── Currency result card ─────────────────────────────────────────────────────
class _CurrencyResultCard extends ConsumerWidget {
  const _CurrencyResultCard({
    required this.total,
    required this.breakdown,
    required this.isSpeaking,
    required this.isDark,
    required this.teal,
    required this.orange,
    required this.theme,
    required this.onSpeak,
  });
  final String total;
  final List<String> breakdown;
  final bool isSpeaking;
  final bool isDark;
  final Color teal, orange;
  final ThemeData theme;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassmorphismDecoration(dark: isDark).copyWith(
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_rounded,
                    size: 18, color: Color(0xFF22C55E)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.currencyTotal,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: teal,
                  ),
                ),
              ),
              _SpeakButton(
                isSpeaking: isSpeaking,
                teal: teal,
                isDark: isDark,
                onTap: onSpeak,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Total in gradient paint
          Text(
            total,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [const Color(0xFF22C55E), teal],
                ).createShader(const Rect.fromLTWH(0, 0, 260, 40)),
            ),
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              s.currencyBreakdownLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: breakdown.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.1),
                    borderRadius: IsharaColors.pillRadius,
                    border: Border.all(
                        color: const Color(0xFF22C55E).withOpacity(0.3)),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Objects result card ──────────────────────────────────────────────────────
class _ObjectsResultCard extends ConsumerWidget {
  const _ObjectsResultCard({
    required this.items,
    required this.isSpeaking,
    required this.isDark,
    required this.teal,
    required this.theme,
    required this.onSpeak,
  });
  final List<DetectedObject> items;
  final bool isSpeaking;
  final bool isDark;
  final Color teal;
  final ThemeData theme;
  final VoidCallback onSpeak;

  static const _chipColors = [
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
    Color(0xFF22C55E),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassmorphismDecoration(dark: isDark).copyWith(
        border: Border.all(color: teal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category_rounded, size: 16, color: teal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.detectedObjects,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14, color: teal),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.1),
                  borderRadius: IsharaColors.pillRadius,
                ),
                child: Text('${items.length}',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: teal)),
              ),
              const SizedBox(width: 8),
              _SpeakButton(
                isSpeaking: isSpeaking,
                teal: teal,
                isDark: isDark,
                onTap: onSpeak,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final chipColor = _chipColors[i % _chipColors.length];
              final pct = (item.confidence * 100).toStringAsFixed(0);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: chipColor.withOpacity(0.1),
                  borderRadius: IsharaColors.pillRadius,
                  border: Border.all(color: chipColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: chipColor),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: chipColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$pct%',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: chipColor),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 60 * i), duration: 300.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    delay: Duration(milliseconds: 60 * i),
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder card ─────────────────────────────────────────────────────────
class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.label,
    required this.body,
    required this.isDark,
    required this.teal,
    required this.theme,
  });
  final IconData icon;
  final String label, body;
  final bool isDark;
  final Color teal;
  final ThemeData theme;

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
              Text(label,
                  style: TextStyle(
                      color: teal, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────
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
  final bool gradient, isDark, loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient && onTap != null
              ? isharaHorizontalGradient(dark: isDark)
              : null,
          color: gradient ? null : Colors.transparent,
          borderRadius: IsharaColors.cardRadius,
          border: gradient
              ? null
              : Border.all(
                  color: onTap != null ? teal : teal.withOpacity(0.3),
                ),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: gradient ? Colors.white : teal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: gradient ? Colors.white : teal,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
