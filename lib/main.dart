import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/api/auth_provider.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/settings/accessibility_settings.dart';
import 'src/core/settings/app_settings_controller.dart';
import 'src/core/theme/ishara_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const IsharaApp(),
    ),
  );
}

class IsharaApp extends ConsumerWidget {
  const IsharaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final access = ref.watch(accessibilityProvider);
    final router = ref.watch(goRouterProvider);

    final lightTheme = applyAccessibilityToTheme(buildIsharaLightTheme(), access);
    final darkTheme = applyAccessibilityToTheme(buildIsharaDarkTheme(), access);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp.router(
        title: 'Ishara',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: settings.themeMode,
        routerConfig: router,
        locale: settings.locale,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(access.textScale.clamp(0.8, 2.0)),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
