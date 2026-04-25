/// Accessibility preferences (auto-TTS, contrast, color-blind palettes,
/// dyslexia font, large text, motor mode, haptics).
///
/// Persisted locally via SharedPreferences and synced to the server at
/// `/api/accessibility` so the same settings follow the user across devices.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/auth_provider.dart';

enum ColorBlindMode { none, deuter, protan, tritan }

class AccessibilitySettings {
  const AccessibilitySettings({
    this.autoTts = false,
    this.highContrast = false,
    this.colorBlindMode = ColorBlindMode.none,
    this.dyslexiaFont = false,
    this.textScale = 1.0,
    this.motorMode = false,
    this.reduceMotion = false,
    this.hapticsOnEveryAction = false,
    this.signLangPreferred = false,
    this.vibrationLevel = 3,
    this.ttsRate = 0.5,
  });

  final bool autoTts;
  final bool highContrast;
  final ColorBlindMode colorBlindMode;
  final bool dyslexiaFont;
  final double textScale;
  final bool motorMode;
  final bool reduceMotion;
  final bool hapticsOnEveryAction;
  final bool signLangPreferred;
  final int vibrationLevel;
  final double ttsRate;

  AccessibilitySettings copyWith({
    bool? autoTts,
    bool? highContrast,
    ColorBlindMode? colorBlindMode,
    bool? dyslexiaFont,
    double? textScale,
    bool? motorMode,
    bool? reduceMotion,
    bool? hapticsOnEveryAction,
    bool? signLangPreferred,
    int? vibrationLevel,
    double? ttsRate,
  }) =>
      AccessibilitySettings(
        autoTts: autoTts ?? this.autoTts,
        highContrast: highContrast ?? this.highContrast,
        colorBlindMode: colorBlindMode ?? this.colorBlindMode,
        dyslexiaFont: dyslexiaFont ?? this.dyslexiaFont,
        textScale: textScale ?? this.textScale,
        motorMode: motorMode ?? this.motorMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        hapticsOnEveryAction: hapticsOnEveryAction ?? this.hapticsOnEveryAction,
        signLangPreferred: signLangPreferred ?? this.signLangPreferred,
        vibrationLevel: vibrationLevel ?? this.vibrationLevel,
        ttsRate: ttsRate ?? this.ttsRate,
      );

  Map<String, dynamic> toJson() => {
        'autoTts': autoTts,
        'highContrast': highContrast,
        'colorBlindMode': colorBlindMode.name,
        'dyslexiaFont': dyslexiaFont,
        'textScale': textScale,
        'motorMode': motorMode,
        'reduceMotion': reduceMotion,
        'hapticsOnEveryAction': hapticsOnEveryAction,
        'signLangPreferred': signLangPreferred,
        'vibrationLevel': vibrationLevel,
        'ttsRate': ttsRate,
      };

  factory AccessibilitySettings.fromJson(Map<String, dynamic> j) {
    final cb = (j['colorBlindMode'] ?? 'none').toString();
    return AccessibilitySettings(
      autoTts: j['autoTts'] == true,
      highContrast: j['highContrast'] == true,
      colorBlindMode: ColorBlindMode.values.firstWhere(
        (e) => e.name == cb,
        orElse: () => ColorBlindMode.none,
      ),
      dyslexiaFont: j['dyslexiaFont'] == true,
      textScale: (j['textScale'] is num) ? (j['textScale'] as num).toDouble() : 1.0,
      motorMode: j['motorMode'] == true,
      reduceMotion: j['reduceMotion'] == true,
      hapticsOnEveryAction: j['hapticsOnEveryAction'] == true,
      signLangPreferred: j['signLangPreferred'] == true,
      vibrationLevel: (j['vibrationLevel'] is num) ? (j['vibrationLevel'] as num).toInt() : 3,
      ttsRate: (j['ttsRate'] is num) ? (j['ttsRate'] as num).toDouble() : 0.5,
    );
  }
}

class AccessibilityController extends StateNotifier<AccessibilitySettings> {
  AccessibilityController(this._prefs, this._api) : super(const AccessibilitySettings()) {
    _hydrate();
  }
  final SharedPreferences _prefs;
  final ApiClient _api;
  static const _key = 'accessibility_prefs_v1';

  Future<void> _hydrate() async {
    final raw = _prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = AccessibilitySettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    // Try to refresh from server in the background.
    try {
      final r = await _api.get('/api/accessibility');
      final m = (r.data['prefs'] as Map?)?.cast<String, dynamic>();
      if (m != null) {
        state = AccessibilitySettings.fromJson(m);
        await _prefs.setString(_key, jsonEncode(state.toJson()));
      }
    } catch (_) {}
  }

  Future<void> update(AccessibilitySettings s) async {
    state = s;
    await _prefs.setString(_key, jsonEncode(s.toJson()));
    try {
      await _api.put('/api/accessibility', data: s.toJson());
    } catch (_) {
      // Best-effort; local persistence already done.
    }
  }
}

final accessibilityProvider = StateNotifierProvider<AccessibilityController, AccessibilitySettings>((ref) {
  return AccessibilityController(ref.watch(sharedPreferencesProvider), ref.watch(apiClientProvider));
});

/// Maps current settings to a [TextTheme] / colour overrides for the active theme.
ThemeData applyAccessibilityToTheme(ThemeData base, AccessibilitySettings s) {
  ColorScheme cs = base.colorScheme;
  if (s.highContrast) {
    cs = cs.copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    );
  }
  switch (s.colorBlindMode) {
    case ColorBlindMode.deuter:
      cs = cs.copyWith(primary: const Color(0xFF005AB5), secondary: const Color(0xFFDC3220));
      break;
    case ColorBlindMode.protan:
      cs = cs.copyWith(primary: const Color(0xFF0072B2), secondary: const Color(0xFFE69F00));
      break;
    case ColorBlindMode.tritan:
      cs = cs.copyWith(primary: const Color(0xFFCC79A7), secondary: const Color(0xFF009E73));
      break;
    case ColorBlindMode.none:
      break;
  }
  return base.copyWith(
    colorScheme: cs,
    visualDensity: s.motorMode ? const VisualDensity(horizontal: 1.5, vertical: 1.5) : base.visualDensity,
  );
}
