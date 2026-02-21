import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LimitExceededException implements Exception {
  const LimitExceededException();
}

class UsageLimiter {
  static const _key = 'ai_daily_usage';
  // 테스트 기간: 100회 / 프로덕션: 5회로 변경
  static const kDailyLimit = 100;

  Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final raw = prefs.getString(_key);
    if (raw == null) return 0;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['date'] == today) return json['count'] as int;
    } catch (_) {}
    return 0;
  }

  Future<void> checkAndIncrement() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final raw = prefs.getString(_key);
    int count = 0;
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (json['date'] == today) count = json['count'] as int;
      } catch (_) {}
    }
    if (count >= kDailyLimit) throw const LimitExceededException();
    await prefs.setString(
      _key,
      jsonEncode({'date': today, 'count': count + 1}),
    );
  }

  String _today() => DateTime.now().toIso8601String().substring(0, 10);
}

final usageLimiterProvider = Provider<UsageLimiter>((ref) => UsageLimiter());
