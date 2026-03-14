import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported languages in the Ishara app.
enum IsharaLanguage { en, ar }

class AppSettingsState {
  const AppSettingsState({
    required this.themeMode,
    required this.language,
  });

  final ThemeMode themeMode;
  final IsharaLanguage language;

  Locale get locale => switch (language) {
        IsharaLanguage.en => const Locale('en'),
        IsharaLanguage.ar => const Locale('ar'),
      };

  TextDirection get textDirection =>
      language == IsharaLanguage.ar ? TextDirection.rtl : TextDirection.ltr;

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    IsharaLanguage? language,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

class AppSettingsController extends StateNotifier<AppSettingsState> {
  AppSettingsController()
      : super(const AppSettingsState(
          themeMode: ThemeMode.system,
          language: IsharaLanguage.en,
        ));

  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setTheme(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleLanguage() {
    state = state.copyWith(
      language:
          state.language == IsharaLanguage.en ? IsharaLanguage.ar : IsharaLanguage.en,
    );
  }

  void setLanguage(IsharaLanguage language) {
    state = state.copyWith(language: language);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettingsState>(
  (ref) => AppSettingsController(),
);

