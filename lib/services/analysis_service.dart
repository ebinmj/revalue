import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AnalysisApiException implements Exception {
  const AnalysisApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AnalysisService {
  AnalysisService({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? _defaultBaseUrl).replaceAll(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  final http.Client _client;

  static String get _defaultBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  final String baseUrl;

  Future<Map<String, dynamic>> analyzeImage({
    required Uint8List imageBytes,
    required String message,
    required String mode,
    String? conversationId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/analyze'),
    );

    final compressedImage = await _compressImage(imageBytes);
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        compressedImage,
        filename: 'upload.png',
        contentType: http.MediaType('image', 'png'),
      ),
    );
    request.fields['message'] = message;
    request.fields['mode'] = mode;
    if (conversationId != null && conversationId.isNotEmpty) {
      request.fields['conversation_id'] = conversationId;
    }

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final rawBody = await streamed.stream.bytesToString();
      final decoded = jsonDecode(rawBody);

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw AnalysisApiException(_errorMessage(decoded, streamed.statusCode));
      }

      if (decoded is! Map<String, dynamic>) {
        throw const AnalysisApiException(
          'The backend returned an invalid response.',
        );
      }

      return decoded;
    } on AnalysisApiException {
      rethrow;
    } catch (_) {
      throw const AnalysisApiException(
        'Unable to connect to ReValue AI. Check that the backend is running and try again.',
      );
    }
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    if (imageBytes.lengthInBytes <= 250000) {
      return imageBytes;
    }

    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: 1536,
      targetHeight: 1536,
    );
    final frame = await codec.getNextFrame();
    final sourceImage = frame.image;
    final maxDimension = 1536.0;
    final scale = sourceImage.width > sourceImage.height
        ? maxDimension / sourceImage.width
        : maxDimension / sourceImage.height;
    final targetWidth = (sourceImage.width * scale).round();
    final targetHeight = (sourceImage.height * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      sourceImage,
      ui.Rect.fromLTWH(
        0,
        0,
        sourceImage.width.toDouble(),
        sourceImage.height.toDouble(),
      ),
      ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    final resized = await picture.toImage(targetWidth, targetHeight);
    final byteData = await resized.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List() ?? imageBytes;
  }

  String _errorMessage(Object decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
      if (decoded['message'] is String) {
        return decoded['message'] as String;
      }
    }
    return 'The backend returned an error ($statusCode).';
  }
}
