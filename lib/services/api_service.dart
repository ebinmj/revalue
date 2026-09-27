import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/analysis_data.dart';
import '../models/api_models.dart';
import '../models/marketplace_listing.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl, http.Client? client, this._accessTokenProvider})
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
  final String? Function()? _accessTokenProvider;

  Future<void> ensureProfile({required String name}) async {
    await _marketplaceRequest(
      'POST',
      '/api/auth/profile',
      body: {'name': name},
    );
  }

  Future<Map<String, dynamic>> _marketplaceRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final token = _accessTokenProvider?.call();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please log in again.',
      );
    }

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 30));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_errorMessage(decoded, response.statusCode));
      }
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('The backend returned an invalid response.');
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The marketplace request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'ReValue could not reach the backend. Check your connection and try again.',
      );
    } on FormatException {
      throw const ApiException('The backend returned invalid JSON.');
    } catch (_) {
      throw const ApiException('Marketplace request failed. Please try again.');
    }
  }

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

  Future<List<MarketplaceListing>> getMarketplaceListings({
    String query = '',
    String? category,
    String? condition,
    String? status,
    bool mine = false,
  }) async {
    final queryParameters = <String, String>{};
    if (query.trim().isNotEmpty) queryParameters['search'] = query.trim();
    if (category != null) queryParameters['category'] = category;
    if (condition != null) queryParameters['condition'] = condition;
    if (status != null) queryParameters['status'] = status;
    if (mine) queryParameters['mine'] = 'true';
    final response = await _marketplaceRequest(
      'GET',
      '/api/marketplace/listings',
      query: queryParameters,
    );
    final rows = response['listings'];
    if (rows is! List) {
      throw const ApiException(
        'The backend returned invalid marketplace data.',
      );
    }
    return rows
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceListing.fromJson)
        .toList();
  }

  Future<MarketplaceListing> createMarketplaceListing({
    required String title,
    required String description,
    required String category,
    required String condition,
    required double price,
    String currency = 'INR',
    String? imageUrl,
  }) async {
    final response = await _marketplaceRequest(
      'POST',
      '/api/marketplace/listings',
      body: {
        'title': title,
        'description': description,
        'category': category,
        'condition': condition,
        'price': price,
        'currency': currency,
        'image_url': imageUrl,
      },
    );
    return MarketplaceListing.fromJson(response);
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
