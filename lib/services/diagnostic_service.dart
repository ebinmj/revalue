import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/diagnostic_models.dart';

class DiagnosticApiException implements Exception {
  const DiagnosticApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Service that talks to the FastAPI diagnostic endpoints.
class DiagnosticService {
  DiagnosticService({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? _defaultBaseUrl).replaceAll(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  static String get _defaultBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  final String baseUrl;
  final http.Client _client;

  /// Start a new diagnostic session with an image and initial description.
  Future<DiagnosticStartResponse> startDiagnostic({
    required Uint8List? imageBytes,
    required String description,
  }) async {
    final body = <String, dynamic>{'description': description};
    if (imageBytes != null) {
      body['image_b64'] =
          'data:image/jpeg;base64,${base64Encode(imageBytes)}';
    }
    final json = await _post('/api/diagnostic/start', body);
    return DiagnosticStartResponse.fromJson(json);
  }

  /// Continue a diagnostic session with answers to follow-up questions.
  Future<DiagnosticContinueResponse> continueDiagnostic({
    required String sessionId,
    required List<String> answers,
  }) async {
    final json = await _post('/api/diagnostic/continue', {
      'session_id': sessionId,
      'answers': answers,
    });
    return DiagnosticContinueResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail =
            decoded is Map<String, dynamic> && decoded['detail'] is String
                ? decoded['detail'] as String
                : 'Backend error (${response.statusCode}).';
        throw DiagnosticApiException(detail);
      }
      if (decoded is! Map<String, dynamic>) {
        throw const DiagnosticApiException(
          'The backend returned an invalid response.',
        );
      }
      return decoded;
    } on DiagnosticApiException {
      rethrow;
    } catch (_) {
      throw const DiagnosticApiException(
        'ReValue could not reach the backend. Check your connection and try again.',
      );
    }
  }
}
