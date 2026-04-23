import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/routing/app_router.dart';
import '../data/emergency_contact_service.dart';
import 'safety_controller.dart';

enum SafetyInitialTab { dashboard, sos }

class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key, this.initialTab = SafetyInitialTab.dashboard});
  final SafetyInitialTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(safetyControllerProvider);
    final controller = ref.read(safetyControllerProvider.notifier);
    final s = t(ref);

    if (initialTab == SafetyInitialTab.sos) {
      return _SosFullScreen(
        state: state,
        controller: controller,
        theme: theme,
        isDark: isDark,
      );
    }

    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

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
                20,
                14,
              ),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E0D0D) : const Color(0xFFFFF0F0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback:
                        (b) => const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                        ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                    child: Text(
                      s.safetyTitle,
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
                    s.safetySub,
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
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── SOS big button ───────────────────────────────────────
                _SosBigButton(
                      isDark: isDark,
                      sosLabel: s.sosEmergency,
                      sosSubLabel: s.tapToOpenSos,
                      onTap: () => context.push(AppRoute.sos),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      delay: 100.ms,
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 16),

                // ── Obstacle sensor card ─────────────────────────────────
                _ObstacleCard(
                      state: state,
                      isDark: isDark,
                      theme: theme,
                      teal: teal,
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 200.ms,
                      duration: 300.ms,
                    ),

                const SizedBox(height: 16),

                _EmergencyContactCard(isDark: isDark, teal: teal, theme: theme)
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      delay: 300.ms,
                      duration: 300.ms,
                    ),

                // ── Error banner ─────────────────────────────────────────
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
                  ).animate().shakeX(duration: 400.ms),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _SafetyHeader extends StatelessWidget {
  const _SafetyHeader({
    required this.isDark,
    required this.theme,
    required this.teal,
    required this.orange,
  });
  final bool isDark;
  final ThemeData theme;
  final Color teal, orange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1C0D0D) : const Color(0xFFFFF0F0),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback:
                    (b) => LinearGradient(
                      colors: [const Color(0xFFEF4444), orange],
                    ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                child: Text(
                  'Safety',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideX(begin: -0.1, end: 0, duration: 350.ms),
          const SizedBox(height: 4),
          Text(
            'Emergency alerts & obstacle detection',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
        ],
      ),
    );
  }
}

// ─── SOS button ──────────────────────────────────────────────────────────────
class _SosBigButton extends StatefulWidget {
  const _SosBigButton({
    required this.isDark,
    required this.sosLabel,
    required this.sosSubLabel,
    required this.onTap,
  });
  final bool isDark;
  final String sosLabel;
  final String sosSubLabel;
  final VoidCallback onTap;

  @override
  State<_SosBigButton> createState() => _SosBigButtonState();
}

class _SosBigButtonState extends State<_SosBigButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.sosLabel,
      hint: widget.sosSubLabel,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final glow = 0.2 + _pulseCtrl.value * 0.25;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: IsharaColors.cardRadius,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(glow),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emergency_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sosLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.sosSubLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Obstacle card ────────────────────────────────────────────────────────────
class _ObstacleCard extends ConsumerWidget {
  const _ObstacleCard({
    required this.state,
    required this.isDark,
    required this.theme,
    required this.teal,
  });
  final SafetyState state;
  final bool isDark;
  final ThemeData theme;
  final Color teal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final hasData = state.obstacleReading != null;
    final isClose = hasData && state.obstacleReading!.distanceCm < 40;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassmorphismDecoration(dark: isDark).copyWith(
        border: Border.all(
          color:
              isClose
                  ? theme.colorScheme.error.withOpacity(0.4)
                  : (isDark
                      ? IsharaColors.darkBorder
                      : IsharaColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (isClose ? theme.colorScheme.error : teal).withOpacity(
                    0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.sensors_rounded,
                  color: isClose ? theme.colorScheme.error : teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.obstacleDetection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Source badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (state.glassesConnected
                          ? teal
                          : theme.colorScheme.outline)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.glassesConnected
                          ? Icons.bluetooth_connected
                          : Icons.sim_card_alert_outlined,
                      size: 12,
                      color:
                          state.glassesConnected
                              ? teal
                              : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.glassesConnected ? s.live : s.simulated,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            state.glassesConnected
                                ? teal
                                : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasData) ...[
            _SensorRow(
              label: s.distance,
              value: '${state.obstacleReading!.distanceCm} cm',
              teal: teal,
              theme: theme,
            ),
            if (state.obstacleReading!.leftCm != null)
              _SensorRow(
                label: s.left,
                value: '${state.obstacleReading!.leftCm} cm',
                teal: teal,
                theme: theme,
              ),
            if (state.obstacleReading!.rightCm != null)
              _SensorRow(
                label: s.right,
                value: '${state.obstacleReading!.rightCm} cm',
                teal: teal,
                theme: theme,
              ),
            if (isClose) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        s.obstacleNearby,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ).animate().shakeX(duration: 400.ms),
            ],
          ] else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.connectHardware,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoute.hardwarePairing),
                    icon: const Icon(Icons.bluetooth_searching_rounded),
                    label: Text(s.pairHardware),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({
    required this.label,
    required this.value,
    required this.teal,
    required this.theme,
  });
  final String label, value;
  final Color teal;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: teal),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOS Full Screen – enhanced with pulsing glow button
// ─────────────────────────────────────────────────────────────────────────────
class _SosFullScreen extends ConsumerWidget {
  const _SosFullScreen({
    required this.state,
    required this.controller,
    required this.theme,
    required this.isDark,
  });
  final SafetyState state;
  final SafetyController controller;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = t(ref);
    final isCounting = state.sosPhase == SosPhase.countingDown;
    final isSent = state.sosPhase == SosPhase.sent;
    final isCancelled = state.sosPhase == SosPhase.cancelled;
    final isArmed = state.sosPhase == SosPhase.armed;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A0505) : const Color(0xFFFFF5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              // ── Close ─────────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      if (isCounting) controller.cancelSos();
                      controller.resetSos();
                      context.pop();
                    },
                  ),
                  const Spacer(),
                ],
              ),

              const Spacer(),

              // ── Status title ───────────────────────────────────────────
              Text(
                isSent
                    ? s.helpSent
                    : isCancelled
                    ? s.cancelled
                    : s.sosEmergencyTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color:
                      isSent
                          ? (isDark
                              ? IsharaColors.tealDark
                              : IsharaColors.tealLight)
                          : const Color(0xFFEF4444),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 350.ms),

              const SizedBox(height: 8),

              Text(
                isSent
                    ? s.locationSentMsg
                    : isCancelled
                    ? s.sosCancelledMsg
                    : isArmed
                    ? s.sosArmedTap
                    : isCounting
                    ? s.sosCounting
                    : s.sendLocation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms),

              const Spacer(),

              // ── Main action area ───────────────────────────────────────
              if (isCounting) ...[
                Text(
                      '${state.sosCountdownSeconds}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFEF4444),
                        fontSize: 96,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 800.ms, color: Colors.white38),

                const SizedBox(height: 24),

                _SosActionButton(
                  label: s.cancelSos,
                  color: theme.colorScheme.error,
                  onTap: controller.cancelSos,
                ),
              ] else if (isSent) ...[
                Icon(
                      Icons.check_circle_rounded,
                      size: 96,
                      color:
                          isDark
                              ? IsharaColors.tealDark
                              : IsharaColors.tealLight,
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 300.ms),

                if (state.lastSosLocation != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Lat: ${state.lastSosLocation!.latitude.toStringAsFixed(4)}  '
                    'Lng: ${state.lastSosLocation!.longitude.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                _SosActionButton(
                  label: s.done,
                  color:
                      isDark ? IsharaColors.tealDark : IsharaColors.tealLight,
                  onTap: () {
                    controller.resetSos();
                    context.pop();
                  },
                ),
              ] else if (!isArmed) ...[
                _PulsingSosCircle(
                  onTap: controller.armSos,
                  onLongPress: controller.startSosCountdown,
                ),
                const SizedBox(height: 20),
                Text(
                  s.tapToArm,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                _SosActionButton(
                  label: s.startCountdown,
                  color: const Color(0xFFEF4444),
                  onTap: controller.startSosCountdown,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: controller.resetSos,
                  child: Text(s.cancel),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing red circle SOS trigger
class _PulsingSosCircle extends StatefulWidget {
  const _PulsingSosCircle({required this.onTap, required this.onLongPress});
  final VoidCallback onTap, onLongPress;

  @override
  State<_PulsingSosCircle> createState() => _PulsingSosCircleState();
}

class _PulsingSosCircleState extends State<_PulsingSosCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1200.ms)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'SOS trigger',
      hint: 'Tap to arm, long press to send immediately',
      child: GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onTap();
            },
            onLongPress: () {
              HapticFeedback.heavyImpact();
              widget.onLongPress();
            },
            child: AnimatedBuilder(
              animation: _ctrl,
              builder:
                  (_, __) => Container(
                    width: 172,
                    height: 172,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFEF4444)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFEF4444,
                          ).withOpacity(0.25 + _ctrl.value * 0.3),
                          blurRadius: 30 + _ctrl.value * 20,
                          spreadRadius: 4 + _ctrl.value * 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
            ),
          )
          .animate()
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 400.ms),
    );
  }
}

class _SosActionButton extends StatelessWidget {
  const _SosActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: IsharaColors.cardRadius),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

class _EmergencyContactCard extends ConsumerStatefulWidget {
  const _EmergencyContactCard({
    required this.isDark,
    required this.teal,
    required this.theme,
  });

  final bool isDark;
  final Color teal;
  final ThemeData theme;

  @override
  ConsumerState<_EmergencyContactCard> createState() =>
      _EmergencyContactCardState();
}

class _EmergencyContactCardState extends ConsumerState<_EmergencyContactCard> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  SosMessagingApp _preferredApp = SosMessagingApp.whatsapp;
  bool _editing = false;
  bool _launchingWhatsApp = false;
  bool _launchingTelegram = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contact = ref.read(emergencyContactProvider);
      if (contact == null) return;
      _nameCtrl.text = contact.name;
      _phoneCtrl.text = contact.phone;
      if (mounted) {
        setState(() {
          _preferredApp = contact.preferredApp;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _defaultEmergencyMessage() {
    return 'Emergency alert from Ishara. I need urgent help immediately.';
  }

  Future<void> _saveContact() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showSnack(
        message: 'Please enter both contact name and phone number.',
        success: false,
      );
      return;
    }

    final contact = EmergencyContact(
      name: name,
      phone: phone,
      preferredApp: _preferredApp,
    );
    await ref.read(emergencyContactProvider.notifier).save(contact);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _editing = false);
    _showSnack(message: 'Emergency contact saved.', success: true);
  }

  Future<void> _deleteContact() async {
    await ref.read(emergencyContactProvider.notifier).clear();
    _nameCtrl.clear();
    _phoneCtrl.clear();
    if (!mounted) return;
    setState(() {
      _preferredApp = SosMessagingApp.whatsapp;
      _editing = false;
    });
    _showSnack(message: 'Emergency contact removed.', success: true);
  }

  void _showSnack({required String message, required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? widget.teal : widget.theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchMessagingApp(SosMessagingApp app) async {
    final contact = ref.read(emergencyContactProvider);
    if (contact == null || !contact.isValid) {
      _showSnack(
        message: 'Save an emergency contact before sending messages.',
        success: false,
      );
      return;
    }

    setState(() {
      if (app == SosMessagingApp.whatsapp) {
        _launchingWhatsApp = true;
      } else {
        _launchingTelegram = true;
      }
    });

    final result = await EmergencyContactService.sendMessage(
      contact: contact,
      app: app,
      message: _defaultEmergencyMessage(),
    );

    if (!mounted) return;

    setState(() {
      if (app == SosMessagingApp.whatsapp) {
        _launchingWhatsApp = false;
      } else {
        _launchingTelegram = false;
      }
    });

    _showSnack(message: result.message, success: result.success);
  }

  @override
  Widget build(BuildContext context) {
    final contact = ref.watch(emergencyContactProvider);
    final isDark = widget.isDark;
    final teal = widget.teal;
    final hasSaved = contact != null && contact.isValid;
    const red = Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassmorphismDecoration(
        dark: isDark,
      ).copyWith(border: Border.all(color: red.withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.contact_phone_rounded,
                  size: 18,
                  color: red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (hasSaved && !_editing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _editing = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: teal.withOpacity(0.1),
                          borderRadius: IsharaColors.pillRadius,
                          border: Border.all(color: teal.withOpacity(0.25)),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            color: teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _deleteContact,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: red.withOpacity(0.08),
                          borderRadius: IsharaColors.pillRadius,
                          border: Border.all(color: red.withOpacity(0.2)),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 12,
                            color: red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasSaved && !_editing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: red.withOpacity(0.05),
                borderRadius: IsharaColors.cardRadius,
                border: Border.all(color: red.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 14, color: red),
                      const SizedBox(width: 6),
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 14, color: red),
                      const SizedBox(width: 6),
                      Text(contact.phone, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        contact.preferredApp == SosMessagingApp.whatsapp
                            ? Icons.chat_bubble_rounded
                            : Icons.send_rounded,
                        size: 14,
                        color: red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        contact.preferredApp == SosMessagingApp.whatsapp
                            ? 'Preferred for SOS: WhatsApp'
                            : 'Preferred for SOS: Telegram',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _LaunchActionButton(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFF25D366),
                    loading: _launchingWhatsApp,
                    onTap: () => _launchMessagingApp(SosMessagingApp.whatsapp),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LaunchActionButton(
                    label: 'Telegram',
                    icon: Icons.send_rounded,
                    color: const Color(0xFF0088CC),
                    loading: _launchingTelegram,
                    onTap: () => _launchMessagingApp(SosMessagingApp.telegram),
                  ),
                ),
              ],
            ),
          ],

          if (!hasSaved || _editing) ...[
            _ContactField(
              ctrl: _nameCtrl,
              hintText: 'Contact name',
              icon: Icons.person_rounded,
              isDark: isDark,
              teal: teal,
            ),
            const SizedBox(height: 10),
            _ContactField(
              ctrl: _phoneCtrl,
              hintText: 'Phone number (e.g. 01012345678)',
              icon: Icons.phone_rounded,
              isDark: isDark,
              teal: teal,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferred SOS app:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _AppToggleChip(
                      label: 'WhatsApp',
                      icon: Icons.chat_bubble_rounded,
                      selected: _preferredApp == SosMessagingApp.whatsapp,
                      color: const Color(0xFF25D366),
                      onTap:
                          () => setState(
                            () => _preferredApp = SosMessagingApp.whatsapp,
                          ),
                    ),
                    _AppToggleChip(
                      label: 'Telegram',
                      icon: Icons.send_rounded,
                      selected: _preferredApp == SosMessagingApp.telegram,
                      color: const Color(0xFF0088CC),
                      onTap:
                          () => setState(
                            () => _preferredApp = SosMessagingApp.telegram,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: IsharaColors.cardRadius,
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Contact',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color:
                    isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'SOS sends your live location automatically to this contact.',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaunchActionButton extends StatelessWidget {
  const _LaunchActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: IsharaColors.cardRadius),
        elevation: 0,
      ),
      child:
          loading
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
    );
  }
}

class _ContactField extends StatefulWidget {
  const _ContactField({
    required this.ctrl,
    required this.hintText,
    required this.icon,
    required this.isDark,
    required this.teal,
    this.keyboardType,
  });

  final TextEditingController ctrl;
  final String hintText;
  final IconData icon;
  final bool isDark;
  final Color teal;
  final TextInputType? keyboardType;

  @override
  State<_ContactField> createState() => _ContactFieldState();
}

class _ContactFieldState extends State<_ContactField> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: IsharaColors.cardRadius,
        color:
            widget.isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
        border: Border.all(
          color:
              _focused
                  ? widget.teal.withOpacity(0.6)
                  : (widget.isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.1)),
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow:
            _focused
                ? [
                  BoxShadow(
                    color: widget.teal.withOpacity(0.18),
                    blurRadius: 8,
                  ),
                ]
                : [],
      ),
      child: ClipRRect(
        borderRadius: IsharaColors.cardRadius,
        child: TextField(
          controller: widget.ctrl,
          focusNode: _focus,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: widget.isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _focused ? widget.teal : widget.teal.withOpacity(0.6),
              size: 18,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppToggleChip extends StatelessWidget {
  const _AppToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: IsharaColors.pillRadius,
          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
