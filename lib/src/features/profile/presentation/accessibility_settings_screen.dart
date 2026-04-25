import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/accessibility_settings.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(accessibilityProvider);
    final ctrl = ref.read(accessibilityProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(context, 'Audio (blind / low-vision)'),
          SwitchListTile(
            title: const Text('Auto-TTS everywhere'),
            subtitle: const Text('Speaks screen titles, buttons, and new content automatically.'),
            value: s.autoTts,
            onChanged: (v) => ctrl.update(s.copyWith(autoTts: v)),
          ),
          ListTile(
            title: const Text('TTS speed'),
            subtitle: Slider(
              value: s.ttsRate,
              min: 0.2,
              max: 1.0,
              divisions: 8,
              label: s.ttsRate.toStringAsFixed(2),
              onChanged: (v) => ctrl.update(s.copyWith(ttsRate: v)),
            ),
          ),
          const Divider(),
          _section(context, 'Visual (low-vision / color-blind)'),
          SwitchListTile(
            title: const Text('High contrast'),
            value: s.highContrast,
            onChanged: (v) => ctrl.update(s.copyWith(highContrast: v)),
          ),
          ListTile(
            title: const Text('Color-blind palette'),
            subtitle: DropdownButton<ColorBlindMode>(
              value: s.colorBlindMode,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: ColorBlindMode.none, child: Text('None')),
                DropdownMenuItem(value: ColorBlindMode.deuter, child: Text('Deuteranopia (red-green)')),
                DropdownMenuItem(value: ColorBlindMode.protan, child: Text('Protanopia (red-green)')),
                DropdownMenuItem(value: ColorBlindMode.tritan, child: Text('Tritanopia (blue-yellow)')),
              ],
              onChanged: (v) => v == null ? null : ctrl.update(s.copyWith(colorBlindMode: v)),
            ),
          ),
          const Divider(),
          _section(context, 'Reading (dyslexia)'),
          SwitchListTile(
            title: const Text('Dyslexia-friendly font'),
            subtitle: const Text('Switches the app to OpenDyslexic where available.'),
            value: s.dyslexiaFont,
            onChanged: (v) => ctrl.update(s.copyWith(dyslexiaFont: v)),
          ),
          ListTile(
            title: Text('Text scale: ${(s.textScale * 100).round()}%'),
            subtitle: Slider(
              value: s.textScale,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: '${(s.textScale * 100).round()}%',
              onChanged: (v) => ctrl.update(s.copyWith(textScale: v)),
            ),
          ),
          const Divider(),
          _section(context, 'Motor / one-handed'),
          SwitchListTile(
            title: const Text('Larger touch targets'),
            value: s.motorMode,
            onChanged: (v) => ctrl.update(s.copyWith(motorMode: v)),
          ),
          SwitchListTile(
            title: const Text('Reduce motion'),
            value: s.reduceMotion,
            onChanged: (v) => ctrl.update(s.copyWith(reduceMotion: v)),
          ),
          const Divider(),
          _section(context, 'Deaf'),
          SwitchListTile(
            title: const Text('Haptics on every action'),
            subtitle: const Text('Vibrate on button presses, notifications, and SOS.'),
            value: s.hapticsOnEveryAction,
            onChanged: (v) => ctrl.update(s.copyWith(hapticsOnEveryAction: v)),
          ),
          ListTile(
            title: Text('Vibration intensity: ${s.vibrationLevel}'),
            subtitle: Slider(
              value: s.vibrationLevel.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: '${s.vibrationLevel}',
              onChanged: (v) => ctrl.update(s.copyWith(vibrationLevel: v.round())),
            ),
          ),
          SwitchListTile(
            title: const Text('Prefer sign language'),
            subtitle: const Text('Use sign clips instead of plain text where possible.'),
            value: s.signLangPreferred,
            onChanged: (v) => ctrl.update(s.copyWith(signLangPreferred: v)),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(t, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
