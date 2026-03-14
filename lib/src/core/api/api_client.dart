/// Centralized HTTP client for communicating with the Ishara backend API.
///
/// Uses Dio with JWT token management via SharedPreferences.
/// All API calls go through this client, which handles:
///  - Base URL configuration
///  - Authorization header injection
///  - Token storage/retrieval
///  - Error handling
library;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used in SharedPreferences for auth persistence.
class StorageKeys {
  static const String token = 'auth_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userName = 'user_name';
  static const String userProfilePic = 'user_profile_pic';
  static const String userRole = 'user_role';
  static const String userDisabilityType = 'user_disability_type';
}

class ApiClient {
  // ── Configure the server address here ────────────────────────────
  //
  //  ① Android emulator                → 'http://10.0.2.2:5000'
  //  ② iOS Simulator (same Mac)        → 'http://localhost:5000'
  //  ③ Physical device (phone/tablet)  → 'http://<YOUR_LAN_IP>:5000'
  //
  //  To find your LAN IP on Windows:
  //    Open PowerShell → run:  ipconfig
  //    Look for "IPv4 Address" under your Wi-Fi adapter, e.g. 192.168.1.25
  //    Then set: 'http://192.168.1.25:5000'
  //
  //  ⚠️  Your phone and PC must be on the SAME Wi-Fi network.
  //  ⚠️  Make sure the firewall allows port 5000 (add inbound rule in
  //      Windows Defender Firewall for TCP port 5000 if needed).
  // ─────────────────────────────────────────────────────────────────
  static const String _defaultBaseUrl = 'http://192.168.1.46:5000';

  /// The base URL used by the app. Useful for building dev tool URLs.
  static String get defaultBaseUrl => _defaultBaseUrl;

  late final Dio _dio;
  final SharedPreferences _prefs;

  ApiClient(this._prefs, {String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Automatically attach JWT token to every request.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _prefs.getString(StorageKeys.token);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // If 401 Unauthorized, clear saved auth and let the app redirect.
          if (error.response?.statusCode == 401) {
            clearAuth();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ── Token helpers ─────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _prefs.setString(StorageKeys.token, token);
  }

  String? getToken() => _prefs.getString(StorageKeys.token);

  bool get isLoggedIn {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAuth() async {
    await _prefs.remove(StorageKeys.token);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.userEmail);
    await _prefs.remove(StorageKeys.userName);
    await _prefs.remove(StorageKeys.userProfilePic);
    await _prefs.remove(StorageKeys.userRole);
    await _prefs.remove(StorageKeys.userDisabilityType);
  }

  /// Persists basic user info locally for quick access without network.
  Future<void> saveUserInfo(Map<String, dynamic> user) async {
    if (user['id'] != null) {
      await _prefs.setString(StorageKeys.userId, user['id'].toString());
    }
    if (user['email'] != null) {
      await _prefs.setString(StorageKeys.userEmail, user['email']);
    }
    if (user['name'] != null) {
      await _prefs.setString(StorageKeys.userName, user['name']);
    }
    if (user['profilePic'] != null) {
      await _prefs.setString(StorageKeys.userProfilePic, user['profilePic']);
    }
    if (user['role'] != null) {
      await _prefs.setString(StorageKeys.userRole, user['role']);
    }
    if (user['disabilityType'] != null) {
      await _prefs.setString(
        StorageKeys.userDisabilityType,
        user['disabilityType'],
      );
    }
  }

  /// Returns locally-cached user info (no network call).
  Map<String, String?> getCachedUser() {
    return {
      'id': _prefs.getString(StorageKeys.userId),
      'email': _prefs.getString(StorageKeys.userEmail),
      'name': _prefs.getString(StorageKeys.userName),
      'profilePic': _prefs.getString(StorageKeys.userProfilePic),
      'role': _prefs.getString(StorageKeys.userRole),
      'disabilityType': _prefs.getString(StorageKeys.userDisabilityType),
    };
  }

  // ── HTTP convenience wrappers ─────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  /// For multipart uploads (e.g. avatar images).
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.put(path, data: formData);
  }
}
