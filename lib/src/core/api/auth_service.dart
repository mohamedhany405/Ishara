/// Authentication service for the Ishara app.
///
/// Communicates with the Express.js backend at /api/auth/*.
/// Replaces all Firebase Auth usage with JWT-based authentication.
library;

import 'package:dio/dio.dart';
import 'api_client.dart';

/// Lightweight user model returned by the auth endpoints.
class IsharaUser {
  final String id;
  final String email;
  final String name;
  final String profilePic;
  final String role;
  final bool isVerified;
  final String disabilityType;

  const IsharaUser({
    required this.id,
    required this.email,
    required this.name,
    this.profilePic = '',
    this.role = 'user',
    this.isVerified = false,
    this.disabilityType = 'hearing',
  });

  factory IsharaUser.fromJson(Map<String, dynamic> json) {
    return IsharaUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profilePic: json['profilePic'] ?? '',
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? false,
      disabilityType: json['disabilityType'] ?? 'hearing',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'profilePic': profilePic,
        'role': role,
        'isVerified': isVerified,
        'disabilityType': disabilityType,
      };
}

/// Result wrapper for auth operations.
class AuthResult {
  final bool success;
  final String message;
  final IsharaUser? user;
  final String? token;
  final Map<String, String>? fieldErrors;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.fieldErrors,
  });
}

class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  // ── Register ──────────────────────────────────────────────────────
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String disabilityType = 'hearing',
  }) async {
    try {
      final response = await _api.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'disabilityType': disabilityType,
      });

      return AuthResult(
        success: true,
        message: response.data['message'] ?? 'Registration successful',
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────
  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _api.post('/api/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });

      final data = response.data;
      final token = data['token'] as String?;
      IsharaUser? user;

      if (data['user'] != null) {
        user = IsharaUser.fromJson(data['user']);
      }

      if (token != null) {
        await _api.saveToken(token);
        if (user != null) {
          await _api.saveUserInfo(user.toJson());
        }
      }

      return AuthResult(
        success: true,
        message: data['message'] ?? 'OTP verified',
        user: user,
        token: token,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final token = data['token'] as String?;
      IsharaUser? user;

      if (data['user'] != null) {
        user = IsharaUser.fromJson(data['user']);
      }

      if (token != null) {
        await _api.saveToken(token);
        if (user != null) {
          await _api.saveUserInfo(user.toJson());
        }
      }

      return AuthResult(
        success: true,
        message: data['message'] ?? 'Login successful',
        user: user,
        token: token,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Resend OTP ────────────────────────────────────────────────────
  Future<AuthResult> resendOtp({required String email}) async {
    try {
      final response = await _api.post('/api/auth/resend-otp', data: {
        'email': email,
      });
      return AuthResult(
        success: true,
        message: response.data['message'] ?? 'OTP sent',
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────
  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      final response = await _api.post('/api/auth/forgot-password', data: {
        'email': email,
      });
      return AuthResult(
        success: true,
        message: response.data['message'] ?? 'Reset link sent',
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Reset password ────────────────────────────────────────────────
  Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post('/api/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });
      return AuthResult(
        success: true,
        message: response.data['message'] ?? 'Password reset successful',
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Get current user ──────────────────────────────────────────────
  Future<AuthResult> getCurrentUser() async {
    try {
      final response = await _api.get('/api/auth/me');
      final data = response.data;
      IsharaUser? user;

      if (data['user'] != null) {
        user = IsharaUser.fromJson(data['user']);
        await _api.saveUserInfo(user.toJson());
      }

      return AuthResult(
        success: true,
        message: 'User fetched',
        user: user,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _api.clearAuth();
  }

  // ── Check if logged in ────────────────────────────────────────────
  bool get isLoggedIn => _api.isLoggedIn;

  /// Returns the locally-cached user info (no network).
  IsharaUser? getCachedUser() {
    final cached = _api.getCachedUser();
    if (cached['id'] == null || cached['id']!.isEmpty) return null;
    return IsharaUser(
      id: cached['id']!,
      email: cached['email'] ?? '',
      name: cached['name'] ?? '',
      profilePic: cached['profilePic'] ?? '',
      role: cached['role'] ?? 'user',
      disabilityType: cached['disabilityType'] ?? 'hearing',
    );
  }

  // ── Private error handler ─────────────────────────────────────────
  AuthResult _handleError(DioException e) {
    final data = e.response?.data;
    String message = 'An error occurred. Please try again.';
    Map<String, String>? fieldErrors;

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? message;
      // Collect Joi field-level errors if present
      if (data['errors'] is List) {
        fieldErrors = {};
        for (final err in data['errors']) {
          if (err is Map<String, dynamic>) {
            fieldErrors[err['field'] ?? 'unknown'] = err['message'] ?? '';
          }
        }
      }
    }

    return AuthResult(
      success: false,
      message: message,
      fieldErrors: fieldErrors,
    );
  }
}
