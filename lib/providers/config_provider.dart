import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/secure_config.dart';

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
