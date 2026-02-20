import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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

class GeminiService {
  final GenerativeModel _model;
  final GenerativeModel _jsonModel;

  final GenerativeModel _chatModel;

  GeminiService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
        ),
        _jsonModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        ),
        _chatModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
          systemInstruction: Content.system(
            '당신은 친절한 한국어 계산 도우미입니다. 계산 관련 질문에 명확하고 간결하게 답하며, 결과는 한국 원화 형식(콤마 포함)으로 표시하세요.',
          ),
        );

  Future<String> _callText(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? '';
  }

  Future<String> _callJson(String prompt) async {
    final response = await _jsonModel.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? '{}';
  }

  /// 자연어 입력 계산: "15만원의 10%" → {expression, result, explanation}
  Future<NlpCalcResult> parseNaturalLanguage(String input) async {
    final prompt = '''
사용자의 한국어 계산 요청을 분석하여 JSON으로만 응답하세요.

입력: "$input"

응답 형식 (JSON만, 다른 텍스트 없이):
{"expression": "계산식 예: 150000 * 0.10", "result": 15000, "explanation": "한국어 설명 20자 이내"}
''';
    try {
      final raw = await _callJson(prompt);
      final json = _parseJson(raw);
      return NlpCalcResult(
        expression: json['expression'] as String? ?? input,
        value: (json['result'] as num?)?.toDouble() ?? 0,
        explanation: json['explanation'] as String? ?? '',
      );
    } catch (_) {
      return NlpCalcResult(expression: input, value: 0, explanation: '');
    }
  }

  /// 맥락 해석: "75000 ÷ 3 = 25000" → "회식비 분담이네요"
  Future<String> interpretContext(String expression, double result) async {
    final prompt = '''
계산: "$expression = $result"
이 계산의 맥락을 한국어로 한 줄 팁으로 설명하세요.
가능한 맥락: 할인, 식비/회식 분담, 세금, 급여, 대출, 쇼핑
20자 이내, 친절하게. 계산식 반복 없이 맥락만.
텍스트만 반환.
''';
    return _callText(prompt);
  }

  /// AI 레이블 생성: 히스토리용 짧은 레이블
  Future<String> generateLabel(String expression, double result) async {
    final prompt = '''
계산: "$expression = $result"
이 계산에 어울리는 한국어 레이블을 6자 이내로 작성.
예: 회식 분담, 할인 계산, 세금 계산
따옴표 없이 텍스트만 반환.
''';
    final label = await _callText(prompt);
    return label.replaceAll('"', '').replaceAll("'", '').trim();
  }

  /// AI 채팅: 멀티턴 대화
  Future<String> chat(List<Map<String, String>> messages) async {
    final history = messages
        .where((m) => m['role'] != 'user' || messages.indexOf(m) < messages.length - 1)
        .map((m) => Content(
              m['role'] == 'user' ? 'user' : 'model',
              [TextPart(m['content'] ?? '')],
            ))
        .toList();

    final lastUserMsg = messages.lastWhere(
      (m) => m['role'] == 'user',
      orElse: () => {'role': 'user', 'content': ''},
    )['content'] ?? '';

    final chat = _chatModel.startChat(
      history: history.isEmpty ? null : history,
    );

    final response = await chat.sendMessage(Content.text(lastUserMsg));
    return response.text?.trim() ?? '응답을 받지 못했습니다.';
  }

  Map<String, dynamic> _parseJson(String raw) {
    // Strip markdown code blocks if present
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '').trim();
    }
    // Simple JSON parse using dart:convert via jsonDecode
    return _jsonDecode(text);
  }

  Map<String, dynamic> _jsonDecode(String text) {
    // Use the dart:convert via a helper to avoid import conflict
    final result = <String, dynamic>{};
    try {
      // Find key-value pairs in {"key": value} format
      final exprMatch = RegExp(r'"expression"\s*:\s*"([^"]+)"').firstMatch(text);
      final resultMatch = RegExp(r'"result"\s*:\s*([\d.]+)').firstMatch(text);
      final explainMatch = RegExp(r'"explanation"\s*:\s*"([^"]+)"').firstMatch(text);
      if (exprMatch != null) result['expression'] = exprMatch.group(1);
      if (resultMatch != null) result['result'] = double.tryParse(resultMatch.group(1)!);
      if (explainMatch != null) result['explanation'] = explainMatch.group(1);
    } catch (_) {}
    return result;
  }
}

final geminiServiceProvider = Provider<GeminiService?>((ref) {
  final keyState = ref.watch(apiKeyNotifierProvider);
  final key = keyState.valueOrNull;
  if (key == null || key.isEmpty) return null;
  return GeminiService(key);
});
