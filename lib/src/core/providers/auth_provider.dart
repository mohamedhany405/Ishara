import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// ─── Auth state ───────────────────────────────────────────────────────────────
enum AuthStatus { loading, authenticated, unauthenticated, guest }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  const AuthState({required this.status, this.user, this.error});

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.guest() : this(status: AuthStatus.guest);
  const AuthState.unauthed() : this(status: AuthStatus.unauthenticated);

  AuthState copyWith({AuthStatus? status, AuthUser? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;
  bool get canUseApp => isLoggedIn || isGuest;
}

// ─── Provider ─────────────────────────────────────────────────────────────────
class AuthNotifier extends AutoDisposeAsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Try to restore session from secure storage
    final user = await AuthService.getMe();
    if (user != null) {
      return AuthState(status: AuthStatus.authenticated, user: user);
    }
    // Check cached user for faster startup
    final cached = await AuthService.getCachedUser();
    if (cached != null) {
      return AuthState(status: AuthStatus.authenticated, user: cached);
    }
    return const AuthState.unauthed();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Skip auth – allows app use without account
  void skipAsGuest() {
    state = AsyncData(const AuthState.guest());
  }

  Future<AuthResult> login(String email, String password) async {
    state = const AsyncData(AuthState.loading());
    final result = await AuthService.login(email: email, password: password);
    if (result.success && result.user != null) {
      state = AsyncData(
        AuthState(status: AuthStatus.authenticated, user: result.user),
      );
    } else {
      state = AsyncData(const AuthState.unauthed());
    }
    return result;
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String disabilityType,
  }) async {
    return AuthService.register(
      name: name,
      email: email,
      password: password,
      disabilityType: disabilityType,
    );
  }

  Future<AuthResult> verifyOtp(String email, String otp) async {
    final result = await AuthService.verifyOtp(email: email, otp: otp);
    if (result.success && result.user != null) {
      state = AsyncData(
        AuthState(status: AuthStatus.authenticated, user: result.user),
      );
    }
    return result;
  }

  Future<AuthResult> resendOtp(String email) =>
      AuthService.resendOtp(email: email);

  Future<void> logout() async {
    await AuthService.clearSession();
    state = const AsyncData(AuthState.unauthed());
  }
}

final authProvider = AsyncNotifierProvider.autoDispose<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
