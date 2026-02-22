import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../domain/services/ai_service_interface.dart';
import '../domain/services/device_id_service.dart';
import '../domain/services/proxy_ai_service.dart';
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

/// 앱 고유 디바이스 ID (UUID v4, SharedPreferences 영구 저장)
final deviceIdProvider = FutureProvider<String>((ref) async {
  return DeviceIdService.getOrCreate();
});

/// 항상 프록시 서버를 경유하는 AI 서비스.
/// deviceId 로딩 전(null)이면 null 반환.
final aiServiceProvider = Provider<IAiService?>((ref) {
  final deviceId = ref.watch(deviceIdProvider).valueOrNull;
  if (deviceId == null) return null;
  final region = ref.watch(regionProvider);
  return ProxyAiService(http.Client(), region, deviceId);
});
