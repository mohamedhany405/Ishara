/// Riverpod providers for authentication state management.
///
/// These providers replace FirebaseAuth.instance.currentUser and
/// onAuthStateChanged with JWT-based state managed through SharedPreferences.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'data_service.dart';

// ── SharedPreferences singleton ─────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // This must be overridden in main() with a real instance.
  throw UnimplementedError('SharedPreferences not initialized');
});

// ── Core services ───────────────────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  final savedUrl = prefs.getString('server_url')?.trim();
  final isStaleLocalUrl =
      savedUrl != null &&
      (savedUrl.contains('10.0.2.2') || savedUrl.contains('localhost'));

  // Cloud builds should always prefer --dart-define API_BASE_URL.
  final effectiveBaseUrl =
      envBaseUrl.trim().isNotEmpty
          ? envBaseUrl
          : (!isStaleLocalUrl && savedUrl != null && savedUrl.isNotEmpty
              ? savedUrl
              : null);

  return ApiClient(prefs, baseUrl: effectiveBaseUrl);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthService(api);
});

final dataServiceProvider = Provider<DataService>((ref) {
  final api = ref.watch(apiClientProvider);
  return DataService(api);
});

// ── Auth state ──────────────────────────────────────────────────────

/// Represents the current authentication state.
enum AuthStatus { unknown, authenticated, unauthenticated, guest }

class AuthState {
  final AuthStatus status;
  final IsharaUser? user;

  const AuthState({this.status = AuthStatus.unknown, this.user});

  AuthState copyWith({AuthStatus? status, IsharaUser? user}) {
    return AuthState(status: status ?? this.status, user: user ?? this.user);
  }

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;
  bool get canUseApp => isLoggedIn || isGuest;
}

/// Manages authentication state (replaces FirebaseAuth.instance streams).
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkCurrentSession();
  }

  /// On startup, check if a valid JWT exists and load user data.
  Future<void> _checkCurrentSession() async {
    if (!_authService.isLoggedIn) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    // Try to validate the token by fetching /me
    final result = await _authService.getCurrentUser();
    if (result.success && result.user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    } else {
      // Token expired or invalid — log out
      await _authService.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with email + password.
  Future<AuthResult> login(String email, String password) async {
    final result = await _authService.login(email: email, password: password);
    if (result.success && result.user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    }
    return result;
  }

  /// Register a new account.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String disabilityType = 'hearing',
  }) async {
    return _authService.register(
      email: email,
      password: password,
      name: name,
      disabilityType: disabilityType,
    );
  }

  /// Verify OTP after registration.
  Future<AuthResult> verifyOtp(String email, String otp) async {
    final result = await _authService.verifyOtp(email: email, otp: otp);
    if (result.success && result.user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
    }
    return result;
  }

  /// Skip auth — allows app use without account.
  void skipAsGuest() {
    state = state.copyWith(status: AuthStatus.guest);
  }

  /// Resend OTP to email.
  Future<AuthResult> resendOtp(String email) async {
    return _authService.resendOtp(email: email);
  }

  /// Logout — clear tokens and reset state.
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Refresh user data from server.
  Future<void> refreshUser() async {
    final result = await _authService.getCurrentUser();
    if (result.success && result.user != null) {
      state = state.copyWith(user: result.user);
    }
  }
}

/// The main auth state provider for the app.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience: true if the user is logged in.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

/// Convenience: current user, or null.
final currentUserProvider = Provider<IsharaUser?>((ref) {
  return ref.watch(authProvider).user;
});
