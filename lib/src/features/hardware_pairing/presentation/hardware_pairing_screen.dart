import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hardware/hardware_connection_service.dart';
import '../../../core/hardware/glasses_provider.dart';
import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_card.dart';
import '../../../core/widgets/ishara_feedback.dart';

class HardwarePairingScreen extends ConsumerStatefulWidget {
  const HardwarePairingScreen({super.key});

  @override
  ConsumerState<HardwarePairingScreen> createState() =>
      _HardwarePairingScreenState();
}

class _HardwarePairingScreenState extends ConsumerState<HardwarePairingScreen> {
  final _hostController = TextEditingController(text: '192.168.4.1');
  final _portController = TextEditingController(text: '8080');
  bool _isConnecting = false;
  String? _error;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });
    try {
      final port = int.parse(_portController.text.trim());
      await ref
          .read(hardwareServiceProvider)
          .connect(_hostController.text.trim(), port);
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t(ref).connectedToGlasses)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
    }
  }

  void _disconnect() {
    ref.read(hardwareServiceProvider).disconnect();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final stateAsync = ref.watch(hardwareStateProvider);
    final sensorAsync = ref.watch(glassesSensorProvider);
    final recordingAsync = ref.watch(glassesRecordingProvider);

    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(s.pairGlasses)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(IsharaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Connection card ──────────────────────────────────────
              IsharaCard(
                padding: const EdgeInsets.all(IsharaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: teal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bluetooth_connected_rounded,
                            color: teal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.connectToGlasses,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.glassesInstructions,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _hostController,
                decoration: InputDecoration(
                  labelText: s.glassesIp,
                  prefixIcon: const Icon(Icons.wifi_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                decoration: InputDecoration(
                  labelText: s.port,
                  prefixIcon: const Icon(Icons.settings_ethernet_rounded),
                ),
                keyboardType: TextInputType.number,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                IsharaCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colorScheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Connect / Disconnect button ─────────────────────────
              stateAsync.when(
                data: (state) {
                  if (state == HardwareConnectionState.connected) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.connected,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.link_off),
                          label: Text(s.disconnect),
                        ),
                      ],
                    );
                  }
                  return FilledButton.icon(
                    onPressed:
                        _isConnecting ||
                                state == HardwareConnectionState.connecting
                            ? null
                            : _connect,
                    icon:
                        _isConnecting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.link),
                    label: Text(_isConnecting ? s.connecting : s.connect),
                  );
                },
                loading:
                    () => IsharaLoadingState(message: s.testing, compact: true),
                error:
                    (_, __) => FilledButton.icon(
                      onPressed: _isConnecting ? null : _connect,
                      icon: const Icon(Icons.link),
                      label: Text(s.retryConnect),
                    ),
              ),

              const SizedBox(height: 24),

              // ── Live glasses info (only when connected) ─────────────
              stateAsync.when(
                data: (state) {
                  if (state != HardwareConnectionState.connected) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: IsharaEmptyState(
                        icon: Icons.bluetooth_disabled_rounded,
                        title: s.glassesStatus,
                        message:
                            'Not connected yet. Use the fields above to connect your glasses.',
                        ctaLabel: s.connect,
                        onCtaTap: _isConnecting ? null : _connect,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(s.glassesStatus, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),

                      // Sensor data
                      IsharaCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.sensors, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: sensorAsync.when(
                                data: (msg) {
                                  final cm = msg.payload?['distance_cm'];
                                  return Text(
                                    'Obstacle: ${cm ?? '—'} cm',
                                    style: theme.textTheme.bodyLarge,
                                  );
                                },
                                loading: () => Text(s.waitingSensor),
                                error: (_, __) => Text(s.sensorError),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Recording controls
                      IsharaCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.mic, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: recordingAsync.when(
                                data:
                                    (isRec) => Text(
                                      isRec
                                          ? s.glassesMicRecording
                                          : s.glassesMicIdle,
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                loading: () => Text(s.micIdle),
                                error: (_, __) => const Text('—'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            recordingAsync.when(
                              data:
                                  (isRec) => IconButton.filledTonal(
                                    icon: Icon(
                                      isRec
                                          ? Icons.stop_rounded
                                          : Icons.fiber_manual_record_rounded,
                                      color:
                                          isRec
                                              ? Colors.red
                                              : theme.colorScheme.primary,
                                    ),
                                    onPressed: () {
                                      final hw = ref.read(
                                        hardwareServiceProvider,
                                      );
                                      isRec
                                          ? hw.stopRecording()
                                          : hw.startRecording();
                                    },
                                  ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Vibrate test
                      OutlinedButton.icon(
                        onPressed:
                            () => ref
                                .read(hardwareServiceProvider)
                                .vibrate(pattern: 'short_pulse'),
                        icon: const Icon(Icons.vibration),
                        label: Text(s.testVibration),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
