import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/region.dart';
import 'ai_service_interface.dart';
import 'gemini_service.dart';

/// 서버 프록시를 통해 AI 기능을 호출하는 서비스.
/// API 키는 서버(GCP Secret Manager)에서 관리되므로 클라이언트에 노출되지 않음.
class ProxyAiService implements IAiService {
  static const _baseUrl = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: '',
  );
  static const _appToken = String.fromEnvironment(
    'PROXY_APP_TOKEN',
    defaultValue: '',
  );

  final http.Client _client;
  final RegionMode _region;
  final String _deviceId;

  // 마지막 응답에서 받은 잔여 횟수 (-1 = 미수신)
  int _remainingToday = -1;
  int get remainingToday => _remainingToday;

  ProxyAiService(this._client, this._region, this._deviceId);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_appToken',
        'X-Device-Id': _deviceId,
        'Content-Type': 'application/json',
      };

  String get _regionParam => _region == RegionMode.kr ? 'kr' : 'global';

  @override
  Future<NlpCalcResult> parseNaturalLanguage(String input) async {
    if (_baseUrl.isEmpty || _appToken.isEmpty) {
      return NlpCalcResult(
        expression: input,
        value: 0,
        isError: true,
        errorMessage: 'Proxy not configured',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/nlp'),
            headers: _headers,
            body: jsonEncode({'input': input, 'region': _regionParam}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('[ProxyAiService] nlp status=${response.statusCode}');

      if (response.statusCode == 429) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = body['error'] as String? ?? 'RATE_LIMITED';
        return NlpCalcResult(
          expression: input,
          value: 0,
          isError: true,
          errorMessage: errorCode,
        );
      }

      if (response.statusCode != 200) {
        return NlpCalcResult(
          expression: input,
          value: 0,
          isError: true,
          errorMessage: 'Server error: ${response.statusCode}',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _remainingToday = (body['remainingToday'] as num?)?.toInt() ?? -1;

      return NlpCalcResult(
        expression: body['expression'] as String? ?? input,
        value: (body['result'] as num).toDouble(),
      );
    } catch (e, st) {
      debugPrint('[ProxyAiService] nlp error: $e\n$st');
      return NlpCalcResult(
        expression: input,
        value: 0,
        isError: true,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<String> chat(List<Map<String, String>> messages) async {
    if (_baseUrl.isEmpty || _appToken.isEmpty) {
      return _region == RegionMode.kr
          ? '서버 설정이 완료되지 않았습니다.'
          : 'Server not configured.';
    }

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/v1/chat'),
            headers: _headers,
            body: jsonEncode({'messages': messages, 'region': _regionParam}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('[ProxyAiService] chat status=${response.statusCode}');

      if (response.statusCode == 429) {
        return _region == RegionMode.kr
            ? '오늘의 AI 사용 한도(50회)에 도달했습니다. 내일 다시 이용해 주세요.'
            : 'Daily AI limit (50) reached. Please try again tomorrow.';
      }

      if (response.statusCode != 200) {
        return _region == RegionMode.kr
            ? '서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.'
            : 'Server error. Please try again later.';
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      _remainingToday = (body['remainingToday'] as num?)?.toInt() ?? -1;
      return body['reply'] as String? ??
          (_region == RegionMode.kr ? '응답을 받지 못했습니다.' : 'No response received.');
    } catch (e, st) {
      debugPrint('[ProxyAiService] chat error: $e\n$st');
      return _region == RegionMode.kr
          ? '연결 오류가 발생했습니다. 네트워크를 확인해 주세요.'
          : 'Connection error. Please check your network.';
    }
  }
}
