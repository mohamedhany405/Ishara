import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/api/auth_provider.dart';
import 'src/core/routing/app_router.dart';
import 'src/core/settings/app_settings_controller.dart';
import 'src/core/theme/ishara_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize SharedPreferences (needed by ApiClient for JWT storage)
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the real SharedPreferences instance
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
    final router = ref.watch(goRouterProvider);

    final lightTheme = buildIsharaLightTheme();
    final darkTheme = buildIsharaDarkTheme();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: MaterialApp.router(
        title: 'Ishara',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: settings.themeMode,
        routerConfig: router,
        locale: settings.locale,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
