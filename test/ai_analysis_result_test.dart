import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:re_value/models/ai_analysis_result.dart';
import 'package:re_value/services/analysis_service.dart';

void main() {
  test('parses the structured Gemini result contract', () {
    final result = AiAnalysisResult.fromJson(_validResponse());

    expect(result.identifiedItem, 'ASUS laptop');
    expect(result.confidence, 'medium');
    expect(result.reduce.recommendation, 'Investigate repair.');
    expect(result.followUpQuestions, ['Does the charging light turn on?']);
  });

  test('rejects missing fields and unsupported confidence values', () {
    final invalidConfidence = _validResponse()..['confidence'] = 'certain';

    expect(
      () => AiAnalysisResult.fromJson(invalidConfidence),
      throwsFormatException,
    );
    expect(
      () => AiAnalysisResult.fromJson({'identified_item': 'Laptop'}),
      throwsFormatException,
    );
  });

  test(
    'uploads actual image bytes and the entered message as multipart',
    () async {
      final imageBytes = Uint8List.fromList([11, 23, 37, 41, 59]);
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/analyze');
        expect(
          request.headers.values.any(
            (value) => value.contains('multipart/form-data'),
          ),
          isTrue,
        );
        expect(_containsBytes(request.bodyBytes, imageBytes), isTrue);
        expect(
          utf8.decode(request.bodyBytes, allowMalformed: true),
          contains('My item stopped working yesterday.'),
        );
        return http.Response(
          jsonEncode(_validResponse()),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = AnalysisService(
        baseUrl: 'http://127.0.0.1:8000',
        client: client,
      );

      final result = await service.analyzeImage(
        imageBytes: imageBytes,
        message: 'My item stopped working yesterday.',
        mode: 'quick_scan',
      );

      expect(result.identifiedItem, 'ASUS laptop');
    },
  );
}

bool _containsBytes(List<int> source, List<int> target) {
  for (var start = 0; start <= source.length - target.length; start++) {
    var matches = true;
    for (var offset = 0; offset < target.length; offset++) {
      if (source[start + offset] != target[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

Map<String, dynamic> _validResponse() => {
  'identified_item': 'ASUS laptop',
  'summary': 'The image shows a laptop; the user reports it will not start.',
  'possible_problem': 'Possible power issue.',
  'confidence': 'medium',
  'reduce': {
    'recommendation': 'Investigate repair.',
    'reason': 'It may be repairable.',
  },
  'reuse': {
    'recommendation': 'Recover usable components.',
    'reason': 'Parts may retain value.',
  },
  'recycle': {
    'recommendation': 'Recycle through an authorized facility.',
    'reason': 'Recover materials.',
  },
  'riddance': {
    'recommendation': 'Dispose responsibly.',
    'reason': 'Use e-waste handling.',
  },
  'follow_up_questions': ['Does the charging light turn on?'],
};
