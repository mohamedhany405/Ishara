import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
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
                    height: 38,
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
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient:
              gradient && onTap != null
                  ? isharaHorizontalGradient(dark: isDark)
                  : null,
          color: gradient ? null : Colors.transparent,
          borderRadius: IsharaColors.cardRadius,
          border:
              gradient
                  ? null
                  : Border.all(
                    color: onTap != null ? teal : teal.withOpacity(0.3),
                  ),
        ),
        child: Center(
          child:
              loading
                  ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: gradient ? Colors.white : teal,
                        size: 20,
                      ),
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
