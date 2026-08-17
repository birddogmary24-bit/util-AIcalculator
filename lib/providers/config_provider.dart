import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../domain/services/ai_service_interface.dart';
import '../domain/services/gemini_service.dart';
import '../domain/services/secure_config.dart';
import 'region_provider.dart';

final apiKeyProvider = FutureProvider<String?>((ref) async {
  return SecureConfig.getApiKey();
});

// Mutable notifier so UI can refresh after user saves a new key
final apiKeyNotifierProvider =
    StateNotifierProvider<ApiKeyNotifier, AsyncValue<String?>>((ref) {
  return ApiKeyNotifier();
});

class ApiKeyNotifier extends StateNotifier<AsyncValue<String?>> {
  ApiKeyNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final key = await SecureConfig.getApiKey();
      state = AsyncValue.data(key);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(String key) async {
    await SecureConfig.setApiKey(key.trim());
    state = AsyncValue.data(key.trim());
  }

  Future<void> delete() async {
    await SecureConfig.deleteApiKey();
    state = const AsyncValue.data(null);
  }

  String? get currentKey => state.valueOrNull;
}

/// Gemini API를 사용하는 AI 서비스 프로바이더.
/// API 키가 설정되어 있을 때만 유효한 IAiService를 반환하고, 없으면 null을 반환합니다.
final aiServiceProvider = Provider<IAiService?>((ref) {
  final keyState = ref.watch(apiKeyNotifierProvider);
  final key = keyState.valueOrNull;
  if (key == null || key.trim().isEmpty) return null;
  final region = ref.watch(regionProvider);
  return GeminiService(http.Client(), key.trim(), region);
});

