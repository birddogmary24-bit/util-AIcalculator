import 'package:util_ai_calculator/domain/services/gemini_service.dart';

/// AI 서비스 공통 인터페이스.
/// GeminiService와 ProxyAiService 모두 이 인터페이스를 구현한다.
abstract class IAiService {
  Future<NlpCalcResult> parseNaturalLanguage(String input);
  Future<String> chat(List<Map<String, String>> messages);
}
