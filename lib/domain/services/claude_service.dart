import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../providers/config_provider.dart';

class NlpCalcResult {
  final String expression;
  final double value;
  final String explanation;

  const NlpCalcResult({
    required this.expression,
    required this.value,
    required this.explanation,
  });
}

class ClaudeService {
  final String apiKey;

  const ClaudeService(this.apiKey);

  Future<Map<String, dynamic>> _call(String prompt) async {
    final response = await http
        .post(
          Uri.parse(ApiConstants.claudeEndpoint),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': ApiConstants.anthropicVersion,
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': ApiConstants.claudeModel,
            'max_tokens': ApiConstants.maxTokens,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        (body['content'] as List).first['text'] as String;
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Future<String> _callText(String prompt) async {
    final response = await http
        .post(
          Uri.parse(ApiConstants.claudeEndpoint),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': ApiConstants.anthropicVersion,
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': ApiConstants.claudeModel,
            'max_tokens': ApiConstants.maxTokens,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ((body['content'] as List).first['text'] as String).trim();
  }

  /// 자연어 입력 계산: "15만원의 10%" → {expression, result, explanation}
  Future<NlpCalcResult> parseNaturalLanguage(String input) async {
    final prompt = '''
당신은 한국어 계산 도우미입니다. 사용자의 한국어 계산 요청을 분석하여 JSON으로만 응답하세요. 다른 텍스트는 절대 포함하지 마세요.

입력: "$input"

다음 JSON 형식으로만 응답:
{"expression": "계산식 예: 150000 * 0.10", "result": 숫자, "explanation": "한국어 설명 20자 이내"}
''';
    final json = await _call(prompt);
    return NlpCalcResult(
      expression: json['expression'] as String? ?? input,
      value: (json['result'] as num?)?.toDouble() ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  /// 맥락 해석: "75000 ÷ 3 = 25000" → "회식비 분담이네요"
  Future<String> interpretContext(String expression, double result) async {
    final prompt = '''
계산: "$expression = $result"
이 계산의 맥락을 파악하여 한국어로 한 줄 팁을 작성하세요.
가능한 맥락: 할인 계산, 식비/회식 분담, 세금/부가세, 급여 계산, 대출/이자, 쇼핑
팁은 20자 이내, 친절하고 구체적으로. 계산식 반복 없이 맥락만 설명.
텍스트만 반환, JSON 아님.
''';
    return _callText(prompt);
  }

  /// AI 레이블 생성: "75000÷3=25000" → "회식 분담"
  Future<String> generateLabel(String expression, double result) async {
    final prompt = '''
계산: "$expression = $result"
이 계산에 어울리는 한국어 레이블을 6자 이내로 작성하세요.
예시: "회식 분담", "할인 계산", "세금 계산", "급여 계산"
텍스트만 반환, 따옴표 없이.
''';
    final label = await _callText(prompt);
    return label.replaceAll('"', '').replaceAll("'", '').trim();
  }

  /// AI 채팅: 자유 대화형 계산 도우미
  Future<String> chat(List<Map<String, String>> messages) async {
    final response = await http
        .post(
          Uri.parse(ApiConstants.claudeEndpoint),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': ApiConstants.anthropicVersion,
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': ApiConstants.claudeModel,
            'max_tokens': 800,
            'system':
                '당신은 친절한 한국어 계산 도우미입니다. 계산 관련 질문에 명확하고 간결하게 답하며, 결과는 한국 원화 형식(콤마 포함)으로 표시하세요.',
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ((body['content'] as List).first['text'] as String).trim();
  }
}

final claudeServiceProvider = Provider<ClaudeService?>((ref) {
  final keyState = ref.watch(apiKeyNotifierProvider);
  final key = keyState.valueOrNull;
  if (key == null || key.isEmpty) return null;
  return ClaudeService(key);
});
