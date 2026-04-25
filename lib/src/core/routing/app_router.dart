import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/shell/presentation/ishara_shell_scaffold.dart';
import '../../features/communicate/presentation/communicate_screen.dart';
import '../../features/vision/presentation/vision_screen.dart';
import '../../features/safety/presentation/safety_screen.dart';
import '../../features/learning/presentation/learning_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/hardware_pairing/presentation/hardware_pairing_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/translator/presentation/text_to_sign_screen.dart';
import '../../features/learning/presentation/quiz_screen.dart';
import '../../features/shop/presentation/products_screen.dart';
import '../../features/shop/presentation/product_detail_screen.dart';
import '../../features/shop/presentation/cart_screen.dart';
import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/profile/presentation/accessibility_settings_screen.dart';
import '../../features/profile/presentation/social_links_screen.dart';
import '../../features/safety/presentation/contacts_screen.dart';
import '../api/auth_provider.dart';

/// Route path constants
abstract class AppRoute {
  static const root = '/';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';

  static const home = '/home';
  static const translator = '/translator';
  static const textToSign = '/translator/text-to-sign';
  static const vision = '/vision';
  static const safety = '/safety';
  static const learning = '/learning';
  static const quiz = '/learning/quiz';
  static const profile = '/profile';
  static const sos = '/sos';
  static const hardwarePairing = '/hardware-pairing';
  static const shop = '/shop';
  static const cart = '/shop/cart';
  static const assistant = '/assistant';
  static const accessibility = '/profile/accessibility';
  static const social = '/profile/social';
  static const contacts = '/profile/contacts';
}

/// Root navigator key – shared so modals can push above the shell.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// A [ChangeNotifier] driven by a provider [Ref].
/// Using [Ref.listen] (not WidgetRef.listen) avoids the
/// "ref.listen can only be used within build" assertion.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// Riverpod provider for the application [GoRouter].
/// Because this uses [Ref.listen] internally, auth changes automatically
/// trigger GoRouter's redirect logic without any WidgetRef dependency.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.root,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      // Let splash through always
      if (loc == AppRoute.root) return null;

      final onAuth =
          loc == AppRoute.login ||
          loc == AppRoute.register ||
          loc == AppRoute.otp;

      // Still initializing — let GoRouter decide next time
      if (auth.status == AuthStatus.unknown) return null;

      // Logged-in or guest → skip auth pages
      if (auth.canUseApp && onAuth) return AppRoute.home;

      // Not authenticated and not on an auth page → force to login
      if (!auth.canUseApp && !onAuth) return AppRoute.login;

      return null;
    },
    routes: [
      // ── Splash ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoute.root,
        name: 'splash',
        pageBuilder: (_, __) => const NoTransitionPage(child: SplashScreen()),
      ),

      // ── Auth (no shell) ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoute.login,
        name: 'login',
        pageBuilder: (_, __) => const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: AppRoute.register,
        name: 'register',
        pageBuilder: (_, __) => const MaterialPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: AppRoute.otp,
        name: 'otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final email = extra['email'] as String? ?? '';
          return MaterialPage(child: OtpScreen(email: email));
        },
      ),

      // ── App shell ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => IsharaShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoute.home,
            name: 'home',
            pageBuilder:
                (_, __) => const NoTransitionPage(child: CommunicateScreen()),
          ),
          GoRoute(
            path: AppRoute.vision,
            name: 'vision',
            pageBuilder:
                (_, __) => const NoTransitionPage(child: VisionScreen()),
          ),
          GoRoute(
            path: AppRoute.safety,
            name: 'safety',
            pageBuilder:
                (_, __) => const NoTransitionPage(child: SafetyScreen()),
          ),
          GoRoute(
            path: AppRoute.learning,
            name: 'learning',
            pageBuilder:
                (_, __) => const NoTransitionPage(child: LearningScreen()),
          ),
          GoRoute(
            path: AppRoute.profile,
            name: 'profile',
            pageBuilder:
                (_, __) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // ── Modals (no shell) ───────────────────────────────────────────────
      GoRoute(
        path: AppRoute.sos,
        name: 'sos',
        pageBuilder:
            (_, __) => const MaterialPage(
              fullscreenDialog: true,
              child: SafetyScreen(initialTab: SafetyInitialTab.sos),
            ),
      ),
      GoRoute(
        path: AppRoute.hardwarePairing,
        name: 'hardware-pairing',
        pageBuilder:
            (_, __) => const MaterialPage(child: HardwarePairingScreen()),
      ),

      // ── New feature routes ──────────────────────────────────────────────
      GoRoute(
        path: AppRoute.textToSign,
        name: 'text-to-sign',
        pageBuilder: (_, __) => const MaterialPage(child: TextToSignScreen()),
      ),
      GoRoute(
        path: AppRoute.quiz,
        name: 'quiz',
        pageBuilder: (_, __) => const MaterialPage(child: QuizScreen()),
      ),
      GoRoute(
        path: AppRoute.shop,
        name: 'shop',
        pageBuilder: (_, __) => const MaterialPage(child: ProductsScreen()),
      ),
      GoRoute(
        path: '/shop/product/:id',
        name: 'shop-product',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MaterialPage(child: ProductDetailScreen(productId: id));
        },
      ),
      GoRoute(
        path: AppRoute.cart,
        name: 'cart',
        pageBuilder: (_, __) => const MaterialPage(child: CartScreen()),
      ),
      GoRoute(
        path: AppRoute.assistant,
        name: 'assistant',
        pageBuilder: (_, __) => const MaterialPage(child: AssistantScreen()),
      ),
      GoRoute(
        path: AppRoute.accessibility,
        name: 'accessibility',
        pageBuilder: (_, __) => const MaterialPage(child: AccessibilitySettingsScreen()),
      ),
      GoRoute(
        path: AppRoute.social,
        name: 'social',
        pageBuilder: (_, __) => const MaterialPage(child: SocialLinksScreen()),
      ),
      GoRoute(
        path: AppRoute.contacts,
        name: 'contacts',
        pageBuilder: (_, __) => const MaterialPage(child: ContactsScreen()),
      ),
    ],
  );
});
