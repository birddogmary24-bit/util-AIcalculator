import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:util_ai_calculator/core/constants/region.dart';
import 'package:util_ai_calculator/domain/services/gemini_service.dart';

void main() {
  group('GeminiService', () {
    test('parseNaturalLanguage 성공적으로 수식과 결과 파싱', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['key'], 'test-api-key');
        expect(request.url.path, contains('gemini-3.1-flash-lite'));

        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'expression': '15000 * 3 + 2000 * 5',
                      'result': 55000,
                    })
                  }
                ],
                'role': 'model'
              }
            }
          ]
        };

        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = GeminiService(mockClient, 'test-api-key', RegionMode.kr);
      final result = await service.parseNaturalLanguage('15000원 3개와 2000원 5개');

      expect(result.isError, false);
      expect(result.expression, '15000 * 3 + 2000 * 5');
      expect(result.value, 55000.0);
    });

    test('parseNaturalLanguage 마크다운 코드블록 JSON 응답 처리', () async {
      final mockClient = MockClient((request) async {
        final rawText = '''```json
{"expression": "30000 * 0.85", "result": 25500}
```''';

        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': rawText}
                ],
                'role': 'model'
              }
            }
          ]
        };

        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = GeminiService(mockClient, 'test-api-key', RegionMode.kr);
      final result = await service.parseNaturalLanguage('3만원 15% 할인');

      expect(result.isError, false);
      expect(result.expression, '30000 * 0.85');
      expect(result.value, 25500.0);
    });

    test('chat 정상 대화 응답', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['contents'], isNotEmpty);
        expect(body['systemInstruction'], isNotNull);

        final responseJson = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '100만원의 15%는 150,000원입니다.'}
                ],
                'role': 'model'
              }
            }
          ]
        };

        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final service = GeminiService(mockClient, 'test-api-key', RegionMode.kr);
      final reply = await service.chat([
        {'role': 'user', 'content': '100만원의 15%는 얼마야?'}
      ]);

      expect(reply, '100만원의 15%는 150,000원입니다.');
    });

    test('잘못된 API 키 (400) 에러 처리', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"message": "API key not valid"}}', 400);
      });

      final service = GeminiService(mockClient, 'invalid-key', RegionMode.kr);
      final result = await service.parseNaturalLanguage('10 + 20');

      expect(result.isError, true);
      expect(result.errorMessage, contains('Gemini API 키가 올바르지 않습니다'));

      final reply = await service.chat([
        {'role': 'user', 'content': '안녕'}
      ]);
      expect(reply, contains('Gemini API 키가 올바르지 않거나 권한이 없습니다'));
    });
  });
}
