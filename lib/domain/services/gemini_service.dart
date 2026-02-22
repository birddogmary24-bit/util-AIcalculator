import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/region.dart';
import '../../providers/config_provider.dart';
import '../../providers/region_provider.dart';
import 'ai_service_interface.dart';

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

class GeminiService implements IAiService {
  final GenerativeModel _jsonModel;
  final GenerativeModel _chatModel;
  final RegionMode _region;

  GeminiService(String apiKey, this._region)
      : _jsonModel = GenerativeModel(
          model: 'gemini-2.0-flash-lite',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            maxOutputTokens: 200,
          ),
        ),
        _chatModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            maxOutputTokens: 80,
          ),
          systemInstruction: Content.system(
            _region == RegionMode.kr
                ? '당신은 친절한 한국어 계산 도우미입니다. 계산 관련 질문에 명확하고 간결하게 답하며, 결과는 한국 원화 형식(콤마 포함)으로 표시하세요.'
                : 'You are a helpful calculator assistant. Answer calculation questions clearly and concisely. Format numbers with commas.',
          ),
        );

  Future<String> _callJson(String prompt) async {
    final response = await _jsonModel.generateContent([Content.text(prompt)]);
    final text = response.text?.trim() ?? '{}';
    debugPrint('[GeminiService] _callJson response: $text');
    return text;
  }

  /// Natural language calculation
  @override
  Future<NlpCalcResult> parseNaturalLanguage(String input) async {
    final prompt = _region == RegionMode.kr
        ? '''
사용자의 한국어 계산 요청을 분석하여 JSON으로만 응답하세요.

입력: "$input"

응답 형식 (JSON만, 다른 텍스트 없이):
{"expression": "계산식 예: 150000 * 0.10", "result": 15000}

중요: result는 반드시 숫자(number)로 반환하세요. 문자열이 아닌 숫자입니다.
'''
        : '''
Analyze the user's calculation request and respond in JSON only.

Input: "$input"

Response format (JSON only, no other text):
{"expression": "e.g. 150000 * 0.10", "result": 15000}

Important: result must be a number, not a string.
''';
    try {
      final raw = await _callJson(prompt);
      final json = _parseJson(raw);
      debugPrint('[GeminiService] parseNaturalLanguage parsed json: $json');
      if (json == null || json['result'] == null) {
        return NlpCalcResult(
          expression: input,
          value: 0,
          isError: true,
          errorMessage: 'Failed to parse AI response: raw=$raw',
        );
      }
      return NlpCalcResult(
        expression: json['expression'] as String? ?? input,
        value: _toDouble(json['result']),
      );
    } catch (e, st) {
      debugPrint('[GeminiService] parseNaturalLanguage exception: $e\n$st');
      return NlpCalcResult(
        expression: input,
        value: 0,
        isError: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// Multi-turn chat — 최근 3쌍(6개)만 참조
  @override
  Future<String> chat(List<Map<String, String>> messages) async {
    // indexOf 대신 lastIndexWhere + sublist 패턴으로 안전하게 처리
    final lastUserIndex = messages.lastIndexWhere((m) => m['role'] == 'user');
    if (lastUserIndex < 0) {
      return _region == RegionMode.kr ? '질문을 입력해주세요.' : 'Please enter a question.';
    }

    final lastUserMsg = messages[lastUserIndex]['content'] ?? '';
    final historyMessages = messages.sublist(0, lastUserIndex);

    // 최근 6개(3쌍)만 히스토리로 사용
    final recentHistory = historyMessages.length > 6
        ? historyMessages.sublist(historyMessages.length - 6)
        : historyMessages;

    final history = recentHistory
        .map((m) => Content(
              m['role'] == 'user' ? 'user' : 'model',
              [TextPart(m['content'] ?? '')],
            ))
        .toList();

    final chatSession = _chatModel.startChat(
      history: history.isEmpty ? null : history,
    );

    final response = await chatSession.sendMessage(Content.text(lastUserMsg));
    final fallback = _region == RegionMode.kr ? '응답을 받지 못했습니다.' : 'No response received.';
    return response.text?.trim() ?? fallback;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic>? _parseJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '').trim();
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

final geminiServiceProvider = Provider<GeminiService?>((ref) {
  final keyState = ref.watch(apiKeyNotifierProvider);
  final key = keyState.valueOrNull;
  final region = ref.watch(regionProvider);
  if (key == null || key.isEmpty) return null;
  return GeminiService(key, region);
});
