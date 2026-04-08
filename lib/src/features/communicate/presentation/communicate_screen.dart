import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hardware/glasses_provider.dart';
import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../translator/data/speech_io_service.dart';
import '../../translator/domain/esl_translation_models.dart';
import '../../translator/presentation/translator_controller.dart';

class CommunicateScreen extends ConsumerStatefulWidget {
  const CommunicateScreen({super.key});

  @override
  ConsumerState<CommunicateScreen> createState() => _CommunicateScreenState();
}

class _CommunicateScreenState extends ConsumerState<CommunicateScreen> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(translatorControllerProvider);
      if (s.inputText.isNotEmpty) _inputController.text = s.inputText;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(translatorControllerProvider);
    final ctrl = ref.read(translatorControllerProvider.notifier);
    final phrases = ref.watch(quickPhrasesProvider);
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    ref.listen(translatorControllerProvider, (_, next) {
      if (next.inputText != _inputController.text) {
        _inputController.text = next.inputText;
      }
    });

    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Compact, fixed header ──────────────────────────────────
            _CompactPageHeader(
              title: s.communicate,
              subtitle: s.communicateSub,
              isDark: isDark,
              teal: teal,
              orange: orange,
            ),

            // ── Scrollable body ─────────────────────────────────────────
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                children: [
                  // ── Status banner ─────────────────────────────────────
                  _StatusBanner(isDark: isDark, teal: teal)
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 250.ms),

                  const SizedBox(height: 12),

                  _DirectionToggle(
                        state: state,
                        ctrl: ctrl,
                        isDark: isDark,
                        teal: teal,
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 300.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        delay: 100.ms,
                        duration: 280.ms,
                      ),

                  const SizedBox(height: 12),

                  _InputCard(
                        state: state,
                        ctrl: ctrl,
                        inputController: _inputController,
                        isDark: isDark,
                        theme: theme,
                        teal: teal,
                      )
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 300.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        delay: 150.ms,
                        duration: 280.ms,
                      ),

                  const SizedBox(height: 12),

                  _OutputCard(
                        state: state,
                        ctrl: ctrl,
                        isDark: isDark,
                        theme: theme,
                        teal: teal,
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 300.ms)
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        delay: 200.ms,
                        duration: 280.ms,
                      ),

                  const SizedBox(height: 16),

                  // Quick phrases – only for AR → ESL
                  if (state.direction ==
                      EslTranslationDirection.arabicToEsl)
                    _QuickPhrases(
                      phrases: phrases,
                      ctrl: ctrl,
                      theme: theme,
                      teal: teal,
                    ).animate().fadeIn(delay: 280.ms, duration: 300.ms),

                  const SizedBox(height: 16),

                  // ── How it works card ─────────────────────────────────
                  _HowItWorksCard(
                        isDark: isDark,
                        teal: teal,
                        orange: orange,
                        direction: state.direction,
                      )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 300.ms)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        delay: 350.ms,
                        duration: 280.ms,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status banner ────────────────────────────────────────────────────────────
class _StatusBanner extends ConsumerWidget {
  const _StatusBanner({required this.isDark, required this.teal});
  final bool isDark;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: teal.withOpacity(0.08),
        borderRadius: IsharaColors.cardRadius,
        border: Border.all(color: teal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: teal,
              boxShadow: [
                BoxShadow(color: teal.withOpacity(0.4), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            s.translationReady,
            style: TextStyle(
              color: teal,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Icon(Icons.bolt_rounded, size: 16, color: teal.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            s.onDevice,
            style: TextStyle(
              color: teal.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Compact page header (used in all 4 screens) ────────────────────────────
class _CompactPageHeader extends StatelessWidget {
  const _CompactPageHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.teal,
    required this.orange,
  });
  final String title, subtitle;
  final bool isDark;
  final Color teal, orange;

  @override
  Widget build(BuildContext context) {
    final colors = [teal, orange];
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1E2B) : const Color(0xFFECFDF9),
            border: Border(
              bottom: BorderSide(
                color:
                    isDark ? IsharaColors.darkBorder : IsharaColors.lightBorder,
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
                          (b) => LinearGradient(colors: colors).createShader(
                            Rect.fromLTWH(0, 0, b.width, b.height),
                          ),
                      child: Text(
                        title,
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
                      subtitle,
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
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms);
  }
}

// ─── Direction toggle ─────────────────────────────────────────────────────────
class _DirectionToggle extends ConsumerWidget {
  const _DirectionToggle({
    required this.state,
    required this.ctrl,
    required this.isDark,
    required this.teal,
  });
  final TranslatorState state;
  final TranslatorController ctrl;
  final bool isDark;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
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
        children: [
          _LangPill(
            label: s.eslToArabic,
            selected:
                state.direction == EslTranslationDirection.eslToArabic,
            teal: teal,
            onTap:
                state.direction == EslTranslationDirection.eslToArabic
                    ? null
                    : ctrl.toggleDirection,
          ),
          _LangPill(
            label: s.arabicToEsl,
            selected:
                state.direction == EslTranslationDirection.arabicToEsl,
            teal: teal,
            onTap:
                state.direction == EslTranslationDirection.arabicToEsl
                    ? null
                    : ctrl.toggleDirection,
          ),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.label,
    required this.selected,
    required this.teal,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color teal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            HapticFeedback.selectionClick();
            onTap!();
          }
        },
        child: AnimatedContainer(
          duration: 220.ms,
          curve: Curves.easeInOut,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? teal : Colors.transparent,
            borderRadius: IsharaColors.pillRadius,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : teal,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Input card ───────────────────────────────────────────────────────────────
class _InputCard extends ConsumerWidget {
  const _InputCard({
    required this.state,
    required this.ctrl,
    required this.inputController,
    required this.isDark,
    required this.theme,
    required this.teal,
  });
  final TranslatorState state;
  final TranslatorController ctrl;
  final TextEditingController inputController;
  final bool isDark;
  final ThemeData theme;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ESL → AR: camera-only mode
    if (state.direction == EslTranslationDirection.eslToArabic) {
      return _EslCameraCard(
        state: state,
        ctrl: ctrl,
        isDark: isDark,
        theme: theme,
        teal: teal,
      );
    }
    // AR → ESL: text + mic mode
    return _ArabicInputCard(
      state: state,
      ctrl: ctrl,
      inputController: inputController,
      isDark: isDark,
      theme: theme,
      teal: teal,
    );
  }
}

// ── ESL → AR : camera card ──────────────────────────────────────────────────
class _EslCameraCard extends ConsumerWidget {
  const _EslCameraCard({
    required this.state,
    required this.ctrl,
    required this.isDark,
    required this.theme,
    required this.teal,
  });
  final TranslatorState state;
  final TranslatorController ctrl;
  final bool isDark;
  final ThemeData theme;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Container(
      decoration: glassmorphismDecoration(dark: isDark),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _CardLabel(
            icon: Icons.videocam_rounded,
            label: s.cameraActive.split(' ').first, // "Camera"
            isDark: isDark,
            teal: teal,
          ),
          const SizedBox(height: 16),
          // ── Animated scan area ──────────────────────
          AnimatedContainer(
            duration: 400.ms,
            height: 120,
            decoration: BoxDecoration(
              color: teal.withOpacity(state.isCameraActive ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: teal.withOpacity(state.isCameraActive ? 0.5 : 0.15),
              ),
            ),
            child: Center(
              child: state.isCameraActive
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: teal,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).shimmer(
                              duration: 1200.ms,
                              color: teal.withOpacity(0.3),
                            ),
                        const SizedBox(height: 10),
                        Text(
                          s.waitingForSigns,
                          style: TextStyle(
                            color: teal,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_rounded,
                          size: 32,
                          color: teal.withOpacity(0.3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.pointCamera,
                          style: TextStyle(
                            color: isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          // ── Start / Stop camera button ──────────────
          _GradientPill(
            label: state.isCameraActive ? s.stopCamera : s.startCamera,
            icon: state.isCameraActive
                ? Icons.stop_rounded
                : Icons.videocam_rounded,
            isDark: isDark,
            teal: teal,
            onTap: ctrl.toggleCamera,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── AR → ESL : text + mic card ──────────────────────────────────────────────
class _ArabicInputCard extends ConsumerWidget {
  const _ArabicInputCard({
    required this.state,
    required this.ctrl,
    required this.inputController,
    required this.isDark,
    required this.theme,
    required this.teal,
  });
  final TranslatorState state;
  final TranslatorController ctrl;
  final TextEditingController inputController;
  final bool isDark;
  final ThemeData theme;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Container(
      decoration: glassmorphismDecoration(dark: isDark),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLabel(
            icon: Icons.edit_note,
            label: s.input,
            isDark: isDark,
            teal: teal,
          ),
          const SizedBox(height: 10),
          TextField(
            minLines: 2,
            maxLines: 5,
            controller: inputController,
            onChanged: ctrl.setInput,
            decoration: InputDecoration(
              hintText: s.typeOrSpeak,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 10),
          // ── Audio source toggle (only when glasses connected) ───
          Builder(builder: (context) {
            final glassesConnected = ref.watch(isGlassesConnectedProvider);
            if (!glassesConnected) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_audio, size: 16, color: teal),
                  const SizedBox(width: 6),
                  Text(s.micSource, style: theme.textTheme.labelSmall),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(s.phone),
                    selected: state.audioSource == AudioSource.phoneMic,
                    onSelected: (_) =>
                        ctrl.setAudioSource(AudioSource.phoneMic),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(s.glasses),
                    selected: state.audioSource == AudioSource.glassesMic,
                    onSelected: (_) =>
                        ctrl.setAudioSource(AudioSource.glassesMic),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: _GradientPill(
                  label: state.isTranslating ? s.translating : s.translate,
                  icon: state.isTranslating ? null : Icons.translate,
                  isDark: isDark,
                  loading: state.isTranslating,
                  teal: teal,
                  onTap: state.isTranslating ? null : ctrl.translate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OutlinePill(
                  label: state.isListening ? s.listening : s.microphone,
                  icon: state.isListening ? Icons.mic : Icons.mic_none,
                  isDark: isDark,
                  active: state.isListening,
                  teal: teal,
                  onTap: state.isListening
                      ? ctrl.stopListening
                      : ctrl.startListening,
                ),
              ),
            ],
          ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Output card ──────────────────────────────────────────────────────────────
class _OutputCard extends ConsumerWidget {
  const _OutputCard({
    required this.state,
    required this.ctrl,
    required this.isDark,
    required this.theme,
    required this.teal,
  });
  final TranslatorState state;
  final TranslatorController ctrl;
  final bool isDark;
  final ThemeData theme;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final hasOutput = state.outputText.isNotEmpty;
    final isEslToAr =
        state.direction == EslTranslationDirection.eslToArabic;
    return Container(
      decoration: glassmorphismDecoration(dark: isDark),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLabel(
            icon: isEslToAr ? Icons.translate : Icons.auto_awesome,
            label: isEslToAr ? s.liveTranslation : s.translation,
            isDark: isDark,
            teal: teal,
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: 300.ms,
            child: Text(
              key: ValueKey(state.outputText),
              hasOutput
                  ? state.outputText
                  : s.translatedTextHere,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: hasOutput
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          if (hasOutput) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _OutlinePill(
                  label: s.speak,
                  icon: Icons.volume_up_rounded,
                  isDark: isDark,
                  teal: teal,
                  onTap: ctrl.speakOutput,
                ),
                if (state.lastResult != null) ...[
                  const Spacer(),
                  Text(
                    '${(state.lastResult!.confidence * 100).toStringAsFixed(0)}% ${s.confident}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? IsharaColors.mutedDark
                          : IsharaColors.mutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AuthFieldsShaker extends StatelessWidget {
  const AuthFieldsShaker({
    super.key,
    required this.shakeKey,
    required this.child,
  });
  final int shakeKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shakeKey == 0) return child;
    return child
        .animate(key: ValueKey(shakeKey))
        .shakeX(amount: 6, duration: 400.ms, hz: 4);
  }
}

// ─── Quick phrases ────────────────────────────────────────────────────────────
class _QuickPhrases extends ConsumerWidget {
  const _QuickPhrases({
    required this.phrases,
    required this.ctrl,
    required this.theme,
    required this.teal,
  });
  final List<QuickPhrase> phrases;
  final TranslatorController ctrl;
  final ThemeData theme;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.quickPhrases,
          style: TextStyle(
            color: teal,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: phrases.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final p = phrases[i];
              return ActionChip(
                label: Text(p.label),
                backgroundColor: teal.withOpacity(0.12),
                side: BorderSide(color: teal.withOpacity(0.3)),
                labelStyle: TextStyle(color: teal, fontWeight: FontWeight.w500),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ctrl.setInput(p.text);
                  ctrl.translate();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── How it works card ────────────────────────────────────────────────────────
class _HowItWorksCard extends ConsumerWidget {
  const _HowItWorksCard({
    required this.isDark,
    required this.teal,
    required this.orange,
    required this.direction,
  });
  final bool isDark;
  final Color teal, orange;
  final EslTranslationDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final steps = direction == EslTranslationDirection.eslToArabic
        ? [
            (Icons.videocam_rounded, s.stepCamera, s.stepCameraDesc),
            (Icons.swap_horiz_rounded, s.stepDirection, s.stepDirectionDesc),
            (Icons.translate_rounded, s.stepTranslate, s.stepTranslateDesc),
            (Icons.volume_up_rounded, s.stepListen, s.stepListenDesc),
          ]
        : [
            (Icons.edit_note_rounded, s.stepType, s.stepTypeDesc),
            (Icons.swap_horiz_rounded, s.stepDirection, s.stepDirectionDesc),
            (Icons.translate_rounded, s.stepTranslate, s.stepTranslateDesc),
            (Icons.volume_up_rounded, s.stepListen, s.stepListenDesc),
          ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassmorphismDecoration(dark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 15, color: orange),
              const SizedBox(width: 6),
              Text(
                s.howItWorks,
                style: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(steps.length, (i) {
            final (icon, title, desc) = steps[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Icon(icon, size: 16, color: teal)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark
                                    ? IsharaColors.mutedDark
                                    : IsharaColors.mutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Pill helpers ─────────────────────────────────────────────────────────────
class IsharaAuthLogo extends ConsumerWidget {
  const IsharaAuthLogo({
    super.key,
    required this.teal,
    required this.orange,
    required this.theme,
  });
  final Color teal, orange;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          t(ref).ishara,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: teal,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '.',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: orange,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.teal,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final Color teal;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: teal),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: teal,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _GradientPill extends StatelessWidget {
  const _GradientPill({
    required this.label,
    required this.isDark,
    required this.teal,
    required this.onTap,
    this.icon,
    this.loading = false,
  });
  final String label;
  final bool isDark, loading;
  final Color teal;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap:
        onTap == null
            ? null
            : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
    child: Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: onTap != null ? isharaHorizontalGradient(dark: isDark) : null,
        color:
            onTap == null
                ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                : null,
        borderRadius: IsharaColors.pillRadius,
      ),
      child: Center(
        child:
            loading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) Icon(icon, color: Colors.white, size: 16),
                    if (icon != null) const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
      ),
    ),
  );
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.teal,
    required this.onTap,
    this.active = false,
  });
  final String label;
  final IconData icon;
  final bool isDark, active;
  final Color teal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap:
        onTap == null
            ? null
            : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              active
                  ? teal
                  : (isDark
                      ? IsharaColors.darkBorder
                      : IsharaColors.lightBorder),
        ),
        borderRadius: IsharaColors.pillRadius,
        color: active ? teal.withOpacity(0.12) : Colors.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                active
                    ? teal
                    : (isDark
                        ? IsharaColors.mutedDark
                        : IsharaColors.mutedLight),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  active
                      ? teal
                      : (isDark
                          ? IsharaColors.mutedDark
                          : IsharaColors.mutedLight),
            ),
          ),
        ],
      ),
    ),
  );
}
