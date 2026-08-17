import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/region.dart';
import 'ai_service_interface.dart';

/// Shared model for NLP calculation results.
class NlpCalcResult {
  final String expression;
  final double value;
  final bool isError;
  final String? errorMessage;

  const NlpCalcResult({
    required this.expression,
    required this.value,
    this.isError = false,
    this.errorMessage,
  });
}

/// Google Gemini API (gemini-3.7-flash) 직접 호출 서비스
class GeminiService implements IAiService {
  // WARNING: 사용자가 명시적으로 지정한 모델입니다. 임의로 다른 버전이나 모델로 변경하지 마세요.
  static const String _model = 'gemini-3.1-flash-lite-latest';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  final http.Client _client;
  final String _apiKey;
  final RegionMode _region;

  GeminiService(this._client, this._apiKey, this._region);

  Uri get _uri => Uri.parse('$_endpoint?key=$_apiKey');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  @override
  Future<NlpCalcResult> parseNaturalLanguage(String input) async {
    if (_apiKey.trim().isEmpty) {
      return NlpCalcResult(
        expression: input,
        value: 0,
        isError: true,
        errorMessage: _region == RegionMode.kr
            ? 'API 키가 설정되지 않았습니다.'
            : 'API key is not configured.',
      );
    }

    final isKr = _region == RegionMode.kr;
    final prompt = isKr
        ? '''
사용자의 한국어 계산 요청을 분석하여 계산식과 최종 결과값을 JSON으로만 응답하세요.

입력: "$input"

응답 형식 (반드시 유효한 JSON만 출력, 추가 설명 없음):
{"expression": "계산식 예: 15000 * 3 + 2000 * 5", "result": 55000}

규칙:
1. result는 반드시 숫자(number)여야 합니다. (문자열 불가)
2. expression은 사용자가 알아보기 쉬운 표준 사칙연산 수식이어야 합니다.
'''
        : '''
Analyze the user's calculation request and return the expression and final numeric result in JSON only.

Input: "$input"

Response format (valid JSON only, no additional explanation):
{"expression": "e.g. 15000 * 3 + 2000 * 5", "result": 55000}

Rules:
1. result must be a number, not a string.
2. expression should be a clear standard arithmetic expression.
''';

    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 200,
        'responseMimeType': 'application/json',
      }
    };

    try {
      final response = await _client
          .post(
            _uri,
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('[GeminiService] nlp response status=${response.statusCode}');

      if (response.statusCode == 400 || response.statusCode == 403) {
        return NlpCalcResult(
          expression: input,
          value: 0,
          isError: true,
          errorMessage: isKr
              ? 'Gemini API 키가 올바르지 않습니다. 키를 다시 확인해 주세요.'
              : 'Invalid Gemini API key. Please check your key.',
        );
      }

      if (response.statusCode == 429) {
        return NlpCalcResult(
          expression: input,
          value: 0,
          isError: true,
          errorMessage: isKr
              ? 'AI 요청 한도에 도달했습니다. 잠시 후 다시 시도해 주세요.'
              : 'API rate limit reached. Please try again later.',
        );
      }

      if (response.statusCode != 200) {
        return NlpCalcResult(
          expression: input,
          value: 0,
          isError: true,
          errorMessage: 'API error: ${response.statusCode}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = body['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return NlpCalcResult(
          expression: input,
          value: 0,
          isError: true,
          errorMessage: 'No response from AI',
        );
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = (parts != null && parts.isNotEmpty)
          ? parts[0]['text'] as String? ?? '{}'
          : '{}';

      final parsedJson = _parseJson(text);
      if (parsedJson == null || parsedJson['result'] == null) {
        return NlpCalcResult(
          expression: input,
          value: 0,
          isError: true,
          errorMessage: 'Failed to parse AI calculation result',
        );
      }

      return NlpCalcResult(
        expression: parsedJson['expression'] as String? ?? input,
        value: _toDouble(parsedJson['result']),
      );
    } catch (e, st) {
      debugPrint('[GeminiService] nlp error: $e\n$st');
      return NlpCalcResult(
        expression: input,
        value: 0,
        isError: true,
        errorMessage: isKr
            ? '연결 오류가 발생했습니다. 네트워크 및 API 키를 확인해 주세요.'
            : 'Connection error. Please check your network and API key.',
      );
    }
  }

  @override
  Future<String> chat(List<Map<String, String>> messages) async {
    if (_apiKey.trim().isEmpty) {
      return _region == RegionMode.kr
          ? 'Gemini API 키가 설정되지 않았습니다. 상단 🔑 아이콘에서 키를 입력해 주세요.'
          : 'Gemini API key is not configured. Please enter your key in settings.';
    }

    final isKr = _region == RegionMode.kr;

    // Build Gemini contents history
    final contents = <Map<String, dynamic>>[];

    // 최근 최대 10개 메시지만 참조
    final recent = messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;

    for (final m in recent) {
      final role = m['role'] == 'user' ? 'user' : 'model';
      final text = m['content'] ?? '';
      if (text.trim().isEmpty) continue;
      contents.add({
        'role': role,
        'parts': [
          {'text': text}
        ]
      });
    }

    if (contents.isEmpty) {
      return isKr ? '질문을 입력해 주세요.' : 'Please enter a question.';
    }

    final systemInstructionText = isKr
        ? '당신은 40~60대 사용자를 위한 친절하고 명확한 AI 계산 도우미입니다. '
            '계산, 할인, 환율, 세금, 일상 숫자 관련 질문에 알기 쉽게 답하고, '
            '금액이나 숫자는 보기 편하게 콤마(,)를 포함해 답변하세요. 너무 길지 않고 핵심 위주로 명확하게 설명하세요.'
        : 'You are a helpful and concise AI calculation assistant. '
            'Answer math, discount, tax, currency, and daily calculation questions clearly. '
            'Format all numbers and currency with commas.';

    final requestBody = {
      'systemInstruction': {
        'parts': [
          {'text': systemInstructionText}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 800,
      }
    };

    try {
      final response = await _client
          .post(
            _uri,
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 25));

      debugPrint('[GeminiService] chat response status=${response.statusCode}');

      if (response.statusCode == 400 || response.statusCode == 403) {
        return isKr
            ? 'Gemini API 키가 올바르지 않거나 권한이 없습니다. 키를 다시 확인해 주세요.'
            : 'Invalid Gemini API key or unauthorized. Please verify your key.';
      }

      if (response.statusCode == 429) {
        return isKr
            ? 'AI 요청 한도에 도달했습니다. 잠시 후 다시 시도해 주세요.'
            : 'AI rate limit reached. Please try again in a few moments.';
      }

      if (response.statusCode != 200) {
        return isKr
            ? '서버 오류(${response.statusCode})가 발생했습니다. 잠시 후 다시 시도해 주세요.'
            : 'Server error (${response.statusCode}). Please try again later.';
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = body['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return isKr ? '응답을 생성하지 못했습니다.' : 'No response generated.';
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return isKr ? '응답을 받지 못했습니다.' : 'No response received.';
      }

      final reply = parts[0]['text'] as String? ?? '';
      return reply.trim().isNotEmpty
          ? reply.trim()
          : (isKr ? '응답 내용이 비어 있습니다.' : 'Empty response.');
    } catch (e, st) {
      debugPrint('[GeminiService] chat error: $e\n$st');
      return isKr
          ? '연결 오류가 발생했습니다. 네트워크 및 API 키 설정을 확인해 주세요.'
          : 'Connection error. Please check your network and API key settings.';
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final sanitized = value.replaceAll(',', '').trim();
      return double.tryParse(sanitized) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic>? _parseJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$'), '')
          .trim();
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}
