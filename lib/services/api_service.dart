import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/analysis_data.dart';
import '../models/api_models.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl, http.Client? client})
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

  Future<ApiAnalysisResponse> analyzeItem({
    required Uint8List imageBytes,
    required String description,
  }) async {
    final imageReference = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
    final response = await _post('/api/analyze', {
      'description': description,
      'image_reference': imageReference,
    });
    return ApiAnalysisResponse.fromJson(response);
  }

  Future<ApiRecommendationResponse> getRecommendation(
    AnalysisData analysis,
  ) async {
    final response = await _post('/api/recommend', {
      'detected_category': analysis.detectedCategory,
      'condition': analysis.condition,
      'visible_components': analysis.visibleComponents,
      'risk_factors': analysis.riskFactors,
    });
    return ApiRecommendationResponse.fromJson(response);
  }

  Future<ApiRepairEstimateResponse> getRepairEstimate(
    AnalysisData analysis,
  ) async {
    final response = await _post('/api/repair-estimate', {
      'detected_category': analysis.detectedCategory,
      'condition': analysis.condition,
      'possible_issue': analysis.possibleIssue,
    });
    return ApiRepairEstimateResponse.fromJson(response);
  }

  Future<ApiMarketplaceResponse> getMarketplaceMatches({
    String query = '',
    String? category,
  }) async {
    final response = await _post('/api/marketplace/match', {
      'query': query,
      'category': category,
    });
    return ApiMarketplaceResponse.fromJson(response);
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
          .timeout(const Duration(seconds: 45));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_errorMessage(decoded, response.statusCode));
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('The backend returned an invalid response.');
      }
      return decoded;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'ReValue could not reach the backend. Check your connection and try again.',
      );
    }
  }

  String _errorMessage(Object decoded, int statusCode) {
    if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
      return decoded['detail'] as String;
    }
    return 'The backend returned an error ($statusCode). Please try again.';
  }
}
