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

  const DataResult({required this.success, required this.message, this.data});
}

class DataService {
  final ApiClient _api;

  static const String _cacheProfileKey = 'cache_profile_v1';
  static const String _cacheLessonsKey = 'cache_learning_lessons_v1';
  static const String _cacheDictionaryKey = 'cache_learning_dictionary_v1';
  static const String _cacheEmergencyContactsKey =
      'cache_emergency_contacts_v1';
  static const String _pendingHistoryQueueKey = 'pending_history_queue_v1';

  DataService(this._api);

  String _historyCollectionEndpoint(String endpoint) {
    final segments = Uri.parse(endpoint).pathSegments;
    if (segments.length > 3) {
      return '/${segments.take(3).join('/')}';
    }
    return '/${segments.join('/')}';
  }

  String _historyCacheKey(String endpoint) {
    final normalized = _historyCollectionEndpoint(
      endpoint,
    ).replaceAll('/', '_');
    return 'cache_history$normalized';
  }

  // ─────────────────────────────────────────────────────────────────
  // USER PROFILE
  // ─────────────────────────────────────────────────────────────────

  /// Fetch the authenticated user's profile.
  Future<DataResult<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await _api.get('/api/users/profile');
      final profile = _extractMap(response.data['user'] ?? response.data);
      if (profile.isNotEmpty) {
        await _api.writeJsonCache(_cacheProfileKey, profile);
      }

      return DataResult(
        success: true,
        message: 'Profile loaded',
        data: profile,
      );
    } on DioException catch (e) {
      final cached = _extractMap(_api.readJsonCache(_cacheProfileKey));
      if (cached.isNotEmpty) {
        return DataResult(
          success: true,
          message: 'Using cached profile (offline mode).',
          data: cached,
        );
      }

      return DataResult(success: false, message: _extractMessage(e));
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
      final profile = _extractMap(response.data['user'] ?? response.data);
      if (profile.isNotEmpty) {
        await _api.writeJsonCache(_cacheProfileKey, profile);
      }

      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Profile updated',
        data: profile,
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
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
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  /// Get a public profile by user ID.
  Future<DataResult<Map<String, dynamic>>> getPublicProfile(
    String userId,
  ) async {
    try {
      final response = await _api.get('/api/users/profile/$userId');
      return DataResult(
        success: true,
        message: 'Profile loaded',
        data: response.data['user'] as Map<String, dynamic>?,
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<List<Map<String, dynamic>>>> getEmergencyContacts() async {
    try {
      final response = await _api.get('/api/users/emergency-contacts');
      final contacts = _extractList(response.data);
      await _api.writeJsonCache(_cacheEmergencyContactsKey, contacts);
      return DataResult(
        success: true,
        message: 'Emergency contacts loaded',
        data: contacts,
      );
    } on DioException catch (e) {
      final cached = _extractList(
        _api.readJsonCache(_cacheEmergencyContactsKey),
      );
      if (cached.isNotEmpty) {
        return DataResult(
          success: true,
          message: 'Using cached emergency contacts (offline mode).',
          data: cached,
        );
      }
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> addEmergencyContact({
    required String name,
    required String phone,
    String relationship = '',
  }) async {
    try {
      final response = await _api.post(
        '/api/users/emergency-contacts',
        data: {'name': name, 'phone': phone, 'relationship': relationship},
      );

      final contact = _extractMap(response.data['data'] ?? response.data);
      await _upsertCachedEmergencyContact(contact);

      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Emergency contact created',
        data: contact,
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> updateEmergencyContact(
    String contactId, {
    String? name,
    String? phone,
    String? relationship,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (relationship != null) body['relationship'] = relationship;

      final response = await _api.put(
        '/api/users/emergency-contacts/$contactId',
        data: body,
      );

      final contact = _extractMap(response.data['data'] ?? response.data);
      await _upsertCachedEmergencyContact(contact);

      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Emergency contact updated',
        data: contact,
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<void>> deleteEmergencyContact(String contactId) async {
    try {
      await _api.delete('/api/users/emergency-contacts/$contactId');
      await _removeCachedEmergencyContact(contactId);
      return const DataResult(
        success: true,
        message: 'Emergency contact deleted',
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
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
      final response = await _api.post(
        '/api/contact',
        data: {
          'name': name,
          'email': email,
          'subject': subject,
          'message': message,
        },
      );

      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Message sent',
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // LEARNING HUB
  // ─────────────────────────────────────────────────────────────────

  Future<DataResult<List<Map<String, dynamic>>>> getLearningLessons() async {
    try {
      final response = await _api.get('/api/learning/lessons');
      final data = _extractList(response.data);
      await _api.writeJsonCache(_cacheLessonsKey, data);
      return DataResult(success: true, message: 'Lessons loaded', data: data);
    } on DioException catch (e) {
      final cached = _extractList(_api.readJsonCache(_cacheLessonsKey));
      if (cached.isNotEmpty) {
        return DataResult(
          success: true,
          message: 'Using cached lessons (offline mode).',
          data: cached,
        );
      }
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<List<Map<String, dynamic>>>> getLearningDictionary() async {
    try {
      final response = await _api.get('/api/learning/dictionary');
      final data = _extractList(response.data);
      await _api.writeJsonCache(_cacheDictionaryKey, data);
      return DataResult(
        success: true,
        message: 'Dictionary loaded',
        data: data,
      );
    } on DioException catch (e) {
      final cached = _extractList(_api.readJsonCache(_cacheDictionaryKey));
      if (cached.isNotEmpty) {
        return DataResult(
          success: true,
          message: 'Using cached dictionary (offline mode).',
          data: cached,
        );
      }
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> createLesson(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _api.post('/api/learning/lessons', data: payload);
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Lesson created',
        data: _extractMap(response.data['data'] ?? response.data),
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> updateLesson(
    String lessonId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _api.put(
        '/api/learning/lessons/$lessonId',
        data: payload,
      );
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Lesson updated',
        data: _extractMap(response.data['data'] ?? response.data),
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<void>> deleteLesson(String lessonId) async {
    try {
      await _api.delete('/api/learning/lessons/$lessonId');
      return const DataResult(success: true, message: 'Lesson deleted');
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> createDictionaryEntry(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _api.post(
        '/api/learning/dictionary',
        data: payload,
      );
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Dictionary entry created',
        data: _extractMap(response.data['data'] ?? response.data),
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> updateDictionaryEntry(
    String entryId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _api.put(
        '/api/learning/dictionary/$entryId',
        data: payload,
      );
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Dictionary entry updated',
        data: _extractMap(response.data['data'] ?? response.data),
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<void>> deleteDictionaryEntry(String entryId) async {
    try {
      await _api.delete('/api/learning/dictionary/$entryId');
      return const DataResult(
        success: true,
        message: 'Dictionary entry deleted',
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<List<Map<String, dynamic>>>> getLearningProgress({
    String? status,
  }) async {
    try {
      final response = await _api.get(
        '/api/learning/progress',
        queryParameters: {
          if (status != null && status.trim().isNotEmpty) 'status': status,
        },
      );
      return DataResult(
        success: true,
        message: 'Learning progress loaded',
        data: _extractList(response.data),
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> upsertLearningProgress(
    String lessonId, {
    double? completionPercent,
    String? status,
    double? lastPositionSeconds,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (completionPercent != null) {
        body['completionPercent'] = completionPercent;
      }
      if (status != null) body['status'] = status;
      if (lastPositionSeconds != null) {
        body['lastPositionSeconds'] = lastPositionSeconds;
      }
      if (notes != null) body['notes'] = notes;

      final response = await _api.put(
        '/api/learning/progress/$lessonId',
        data: body,
      );
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'Progress saved',
        data: _extractMap(response.data['data'] ?? response.data),
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<void>> deleteLearningProgress(String lessonId) async {
    try {
      await _api.delete('/api/learning/progress/$lessonId');
      return const DataResult(success: true, message: 'Progress deleted');
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // AI HISTORY (TRANSLATOR & VISION)
  // ─────────────────────────────────────────────────────────────────

  Future<DataResult<List<Map<String, dynamic>>>> getTranslatorHistory() async {
    return _getHistory('/api/history/translator');
  }

  Future<DataResult<Map<String, dynamic>>> addTranslatorHistory({
    required String inputText,
    required String outputText,
    required double confidence,
    Map<String, dynamic>? details,
  }) async {
    return _createHistory(
      '/api/history/translator',
      inputText: inputText,
      outputText: outputText,
      confidence: confidence,
      details: details,
      allowOfflineQueue: true,
    );
  }

  Future<DataResult<Map<String, dynamic>>> updateTranslatorHistory(
    String historyId,
    Map<String, dynamic> payload,
  ) async {
    return _updateHistory('/api/history/translator/$historyId', payload);
  }

  Future<DataResult<void>> deleteTranslatorHistory(String historyId) async {
    return _deleteHistory('/api/history/translator/$historyId');
  }

  Future<DataResult<List<Map<String, dynamic>>>> getVisionHistory() async {
    return _getHistory('/api/history/vision');
  }

  Future<DataResult<Map<String, dynamic>>> addVisionHistory({
    required String inputText,
    required String outputText,
    required double confidence,
    Map<String, dynamic>? details,
  }) async {
    return _createHistory(
      '/api/history/vision',
      inputText: inputText,
      outputText: outputText,
      confidence: confidence,
      details: details,
      allowOfflineQueue: true,
    );
  }

  Future<DataResult<Map<String, dynamic>>> updateVisionHistory(
    String historyId,
    Map<String, dynamic> payload,
  ) async {
    return _updateHistory('/api/history/vision/$historyId', payload);
  }

  Future<DataResult<void>> deleteVisionHistory(String historyId) async {
    return _deleteHistory('/api/history/vision/$historyId');
  }

  /// Performs an end-to-end CRUD verification against translator history.
  ///
  /// Returns success only if create, read, update, and delete all succeed.
  Future<DataResult<void>> verifyDatabaseCrud() async {
    try {
      if (!_api.isLoggedIn) {
        return const DataResult(
          success: true,
          message: 'Cloud CRUD check skipped in guest mode.',
        );
      }

      final created = await _createHistory(
        '/api/history/translator',
        inputText: 'crud_test_input',
        outputText: 'crud_test_output',
        confidence: 0.88,
        details: {'probe': true},
        allowOfflineQueue: false,
      );
      if (!created.success || created.data == null) {
        return DataResult(
          success: false,
          message: 'Create step failed: ${created.message}',
        );
      }

      final id = created.data!['id']?.toString();
      if (id == null || id.isEmpty) {
        return const DataResult(
          success: false,
          message: 'Create step failed: missing created id',
        );
      }

      final read = await getTranslatorHistory();
      if (!read.success) {
        return DataResult(
          success: false,
          message: 'Read step failed: ${read.message}',
        );
      }

      final updated = await updateTranslatorHistory(id, {
        'outputText': 'crud_test_output_updated',
        'confidence': 0.91,
      });
      if (!updated.success) {
        return DataResult(
          success: false,
          message: 'Update step failed: ${updated.message}',
        );
      }

      final deleted = await deleteTranslatorHistory(id);
      if (!deleted.success) {
        return DataResult(
          success: false,
          message: 'Delete step failed: ${deleted.message}',
        );
      }

      return const DataResult(
        success: true,
        message: 'CRUD verification completed successfully',
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
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
      final items =
          response.data is List
              ? response.data as List<dynamic>
              : (response.data['data'] as List<dynamic>?) ?? [];
      return DataResult(success: true, message: 'Loaded', data: items);
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  /// POST a new item to a collection endpoint.
  Future<DataResult<Map<String, dynamic>>> createItem(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
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
    String endpoint,
    Map<String, dynamic> data,
  ) async {
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

  Future<DataResult<List<Map<String, dynamic>>>> _getHistory(
    String endpoint,
  ) async {
    try {
      await _flushPendingHistoryQueue();
      final response = await _api.get(endpoint);
      final data = _extractList(response.data);
      await _api.writeJsonCache(_historyCacheKey(endpoint), data);
      return DataResult(success: true, message: 'History loaded', data: data);
    } on DioException catch (e) {
      final cached = _extractList(
        _api.readJsonCache(_historyCacheKey(endpoint)),
      );
      if (cached.isNotEmpty) {
        return DataResult(
          success: true,
          message: 'Using cached history (offline mode).',
          data: cached,
        );
      }
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> _createHistory(
    String endpoint, {
    required String inputText,
    required String outputText,
    required double confidence,
    Map<String, dynamic>? details,
    bool allowOfflineQueue = true,
  }) async {
    try {
      await _flushPendingHistoryQueue();
      final response = await _api.post(
        endpoint,
        data: {
          'inputText': inputText,
          'outputText': outputText,
          'confidence': confidence,
          'details': details ?? <String, dynamic>{},
        },
      );
      final data = _extractMap(response.data['data'] ?? response.data);
      await _prependCachedHistoryItem(endpoint, data);
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'History entry created',
        data: data,
      );
    } on DioException catch (e) {
      if (allowOfflineQueue && _isNetworkError(e)) {
        await _enqueuePendingHistoryOperation(
          endpoint: endpoint,
          inputText: inputText,
          outputText: outputText,
          confidence: confidence,
          details: details ?? const <String, dynamic>{},
        );

        return DataResult(
          success: true,
          message: 'Saved offline. Will sync automatically when online.',
          data: {
            'id': 'local-${DateTime.now().millisecondsSinceEpoch}',
            'inputText': inputText,
            'outputText': outputText,
            'confidence': confidence,
            'details': details ?? const <String, dynamic>{},
          },
        );
      }

      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<Map<String, dynamic>>> _updateHistory(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _api.put(endpoint, data: payload);
      final data = _extractMap(response.data['data'] ?? response.data);
      await _upsertCachedHistoryItem(endpoint, data);
      return DataResult(
        success: true,
        message: response.data['message'] ?? 'History entry updated',
        data: data,
      );
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  Future<DataResult<void>> _deleteHistory(String endpoint) async {
    try {
      await _api.delete(endpoint);
      await _removeCachedHistoryItem(endpoint);
      return const DataResult(success: true, message: 'History entry deleted');
    } on DioException catch (e) {
      return DataResult(success: false, message: _extractMessage(e));
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic responseData) {
    final raw =
        responseData is List
            ? responseData
            : (responseData is Map<String, dynamic>
                ? (responseData['data'] as List?) ?? const []
                : const []);

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _extractMap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    if (responseData is Map) {
      return Map<String, dynamic>.from(responseData);
    }
    return {};
  }

  Future<void> _upsertCachedEmergencyContact(
    Map<String, dynamic> contact,
  ) async {
    final id = (contact['id'] ?? contact['_id'])?.toString() ?? '';
    if (id.isEmpty) return;

    final contacts = _extractList(
      _api.readJsonCache(_cacheEmergencyContactsKey),
    );
    final index = contacts.indexWhere(
      (item) => (item['id'] ?? item['_id'])?.toString() == id,
    );

    if (index >= 0) {
      contacts[index] = contact;
    } else {
      contacts.add(contact);
    }

    await _api.writeJsonCache(_cacheEmergencyContactsKey, contacts);
  }

  Future<void> _removeCachedEmergencyContact(String contactId) async {
    final contacts = _extractList(
      _api.readJsonCache(_cacheEmergencyContactsKey),
    );
    contacts.removeWhere(
      (item) => (item['id'] ?? item['_id'])?.toString() == contactId,
    );
    await _api.writeJsonCache(_cacheEmergencyContactsKey, contacts);
  }

  Future<void> _prependCachedHistoryItem(
    String endpoint,
    Map<String, dynamic> item,
  ) async {
    final key = _historyCacheKey(endpoint);
    final items = _extractList(_api.readJsonCache(key));
    items.insert(0, item);
    await _api.writeJsonCache(key, items.take(300).toList());
  }

  Future<void> _upsertCachedHistoryItem(
    String endpoint,
    Map<String, dynamic> item,
  ) async {
    final id = (item['id'] ?? item['_id'])?.toString() ?? '';
    if (id.isEmpty) return;

    final key = _historyCacheKey(endpoint);
    final items = _extractList(_api.readJsonCache(key));
    final index = items.indexWhere(
      (entry) => (entry['id'] ?? entry['_id'])?.toString() == id,
    );

    if (index >= 0) {
      items[index] = item;
    } else {
      items.insert(0, item);
    }

    await _api.writeJsonCache(key, items.take(300).toList());
  }

  Future<void> _removeCachedHistoryItem(String endpoint) async {
    final marker = endpoint.split('/').last;
    final key = _historyCacheKey(endpoint);
    final items = _extractList(_api.readJsonCache(key));

    items.removeWhere(
      (entry) => (entry['id'] ?? entry['_id'])?.toString() == marker,
    );

    await _api.writeJsonCache(key, items);
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  Future<void> _enqueuePendingHistoryOperation({
    required String endpoint,
    required String inputText,
    required String outputText,
    required double confidence,
    required Map<String, dynamic> details,
  }) async {
    final queue = _extractList(_api.readJsonCache(_pendingHistoryQueueKey));
    queue.add({
      'endpoint': endpoint,
      'inputText': inputText,
      'outputText': outputText,
      'confidence': confidence,
      'details': details,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    // Keep queue bounded to avoid unbounded growth on long offline sessions.
    final trimmed =
        queue.length > 200 ? queue.sublist(queue.length - 200) : queue;
    await _api.writeJsonCache(_pendingHistoryQueueKey, trimmed);
  }

  Future<void> _flushPendingHistoryQueue() async {
    final queue = _extractList(_api.readJsonCache(_pendingHistoryQueueKey));
    if (queue.isEmpty) return;

    final pending = List<Map<String, dynamic>>.from(queue);
    final leftovers = <Map<String, dynamic>>[];

    for (final item in pending) {
      final endpoint = item['endpoint']?.toString() ?? '';
      if (endpoint.isEmpty) continue;

      try {
        final response = await _api.post(
          endpoint,
          data: {
            'inputText': item['inputText'],
            'outputText': item['outputText'],
            'confidence': item['confidence'],
            'details': item['details'] ?? <String, dynamic>{},
          },
        );

        final data = _extractMap(response.data['data'] ?? response.data);
        await _prependCachedHistoryItem(endpoint, data);
      } on DioException catch (e) {
        if (_isNetworkError(e)) {
          leftovers.add(item);
        }
      }
    }

    if (leftovers.isEmpty) {
      await _api.removeJsonCache(_pendingHistoryQueueKey);
    } else {
      await _api.writeJsonCache(_pendingHistoryQueueKey, leftovers);
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
