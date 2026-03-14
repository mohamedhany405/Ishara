import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ─── CONFIG ───────────────────────────────────────────────────────────────────
/// Change this to your server's IP when running on a real device.
/// For Android emulator 10.0.2.2 maps to the host machine's localhost.
const String kApiBaseUrl = 'http://10.0.2.2:5000/api/auth';
const String _tokenKey = 'ishara_jwt';
const String _userKey = 'ishara_user';

// ─── DATA MODEL ───────────────────────────────────────────────────────────────
class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? profilePic;
  final String disabilityType;
  final String role;
  final bool isVerified;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.profilePic,
    required this.disabilityType,
    required this.role,
    required this.isVerified,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'] as String? ?? '',
    email: j['email'] as String? ?? '',
    name: j['name'] as String? ?? '',
    profilePic: j['profilePic'] as String?,
    disabilityType: j['disabilityType'] as String? ?? 'hearing',
    role: j['role'] as String? ?? 'user',
    isVerified: j['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'profilePic': profilePic,
    'disabilityType': disabilityType,
    'role': role,
    'isVerified': isVerified,
  };
}

// ─── RESULT WRAPPER ───────────────────────────────────────────────────────────
class AuthResult {
  final bool success;
  final String message;
  final AuthUser? user;
  final bool? needsVerification;
  final String? email; // set when needsVerification is true

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.needsVerification,
    this.email,
  });
}

// ─── SERVICE ─────────────────────────────────────────────────────────────────
class AuthService {
  static const _storage = FlutterSecureStorage();

  // ── Low-level helpers ──────────────────────────────────────────────────────
  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> _saveSession(String token, AuthUser user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Returns the locally cached user (fast, no network).
  static Future<AuthUser?> getCachedUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth endpoints ─────────────────────────────────────────────────────────

  /// POST /api/auth/register
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String disabilityType,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kApiBaseUrl/register'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'disabilityType': disabilityType,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return AuthResult(success: true, message: body['message'] as String);
      }
      return AuthResult(
        success: false,
        message: body['message'] as String? ?? 'Registration failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// POST /api/auth/verify-otp
  static Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kApiBaseUrl/verify-otp'),
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final token = body['token'] as String;
        final user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
        await _saveSession(token, user);
        return AuthResult(
          success: true,
          message: body['message'] as String,
          user: user,
        );
      }
      return AuthResult(
        success: false,
        message: body['message'] as String? ?? 'OTP verification failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// POST /api/auth/resend-otp
  static Future<AuthResult> resendOtp({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kApiBaseUrl/resend-otp'),
            headers: _jsonHeaders,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResult(
        success: response.statusCode == 200,
        message: body['message'] as String? ?? '',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// POST /api/auth/login
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kApiBaseUrl/login'),
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = body['token'] as String;
        final user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
        await _saveSession(token, user);
        return AuthResult(
          success: true,
          message: 'Login successful',
          user: user,
        );
      }

      // 403 = email not verified
      if (response.statusCode == 403) {
        return AuthResult(
          success: false,
          message: body['message'] as String? ?? 'Email not verified',
          needsVerification: true,
          email: body['email'] as String?,
        );
      }

      return AuthResult(
        success: false,
        message: body['message'] as String? ?? 'Login failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// GET /api/auth/me – validates the stored token on server
  static Future<AuthUser?> getMe() async {
    try {
      final headers = await _authHeaders();
      final token = headers['Authorization'];
      if (token == null) return null;

      final response = await http
          .get(Uri.parse('$kApiBaseUrl/me'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final user = AuthUser.fromJson(body['user'] as Map<String, dynamic>);
        // refresh cached user
        await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
