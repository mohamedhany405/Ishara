/// Data service for CRUD operations against the Ishara backend API.
///
/// Replaces all Firestore collection/document operations with REST calls
/// to the Express.js server (MongoDB backend).
library;

import 'package:dio/dio.dart';
import 'api_client.dart';

/// Generic result wrapper for data operations.
class DataResult<T> {
  final bool success;
  final String message;
  final T? data;

  const DataResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class DataService {
  final ApiClient _api;

  DataService(this._api);

  // ─────────────────────────────────────────────────────────────────
  // USER PROFILE
  // ─────────────────────────────────────────────────────────────────

  /// Fetch the authenticated user's profile.
  Future<DataResult<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await _api.get('/api/users/profile');
      return DataResult(
        success: true,
        message: 'Profile loaded',
        data: response.data['user'] as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      return DataResult(
        success: false,
        message: _extractMessage(e),
      );
    }
  }

  /// Update profile fields (name, bio, disabilityType, etc.).
  Future<DataResult<Map<String, dynamic>>> updateProfile({
    String? name,
    String? bio,
    String? disabilityType,
    List<Map<String, String>>? emergencyContacts,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (bio != null) body['bio'] = bio;
      if (disabilityType != null) body['disabilityType'] = disabilityType;
      if (emergencyContacts != null) {
        body['emergencyContacts'] = emergencyContacts;
      }
      if (preferences != null) body['preferences'] = preferences;

      final response = await _api.put('/api/users/update-profile', data: body);

      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Profile updated',
        data: response.data['user'] as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      return DataResult(
        success: false,
        message: _extractMessage(e),
      );
    }
  }

  /// Upload a new avatar image.
  Future<DataResult<String>> updateAvatar(String filePath) async {
    try {
      final response = await _api.uploadFile(
        '/api/users/update-avatar',
        filePath,
        fieldName: 'avatar',
      );

      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Avatar updated',
        data: response.data['avatar'] as String?,
      );
    } on DioException catch (e) {
      return DataResult(
        success: false,
        message: _extractMessage(e),
      );
    }
  }

  /// Get a public profile by user ID.
  Future<DataResult<Map<String, dynamic>>> getPublicProfile(
      String userId) async {
    try {
      final response = await _api.get('/api/users/profile/$userId');
      return DataResult(
        success: true,
        message: 'Profile loaded',
        data: response.data['user'] as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      return DataResult(
        success: false,
        message: _extractMessage(e),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // CONTACT / REPORTS
  // ─────────────────────────────────────────────────────────────────

  /// Submit a contact message / report.
  Future<DataResult<void>> submitContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await _api.post('/api/contact', data: {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      });

      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Message sent',
      );
    } on DioException catch (e) {
      return DataResult(
        success: false,
        message: _extractMessage(e),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // GENERIC COLLECTION HELPERS
  // (Use these for any future collections: watchlists, reviews, etc.)
  // ─────────────────────────────────────────────────────────────────

  /// GET a list of items from a collection endpoint.
  Future<DataResult<List<dynamic>>> getCollection(String endpoint) async {
    try {
      final response = await _api.get(endpoint);
      final items = response.data is List
          ? response.data as List<dynamic>
          : (response.data['data'] as List<dynamic>?) ?? [];
      return DataResult(success: true, message: 'Loaded', data: items);
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  /// POST a new item to a collection endpoint.
  Future<DataResult<Map<String, dynamic>>> createItem(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _api.post(endpoint, data: data);
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Created',
        data: response.data as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  /// PUT an update to an existing item.
  Future<DataResult<Map<String, dynamic>>> updateItem(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _api.put(endpoint, data: data);
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Updated',
        data: response.data as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  /// DELETE an item at a given endpoint.
  Future<DataResult<void>> deleteItem(String endpoint) async {
    try {
      await _api.delete(endpoint);
      return const DataResult(success: true, message: 'Deleted');
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  // ── Private ───────────────────────────────────────────────────────
  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message'] ?? 'An error occurred';
    }
    return 'Network error. Please check your connection.';
  }
}
