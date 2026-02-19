import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureConfig {
  SecureConfig._();

  static const _apiKeyKey = 'claude_api_key';

  // flutter_secure_storage is not ideal for web; fall back to SharedPreferences on web
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<String?> getApiKey() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_apiKeyKey);
    }
    return _storage.read(key: _apiKeyKey);
  }

  static Future<void> setApiKey(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyKey, key);
    } else {
      await _storage.write(key: _apiKeyKey, value: key);
    }
  }

  static Future<void> deleteApiKey() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiKeyKey);
    } else {
      await _storage.delete(key: _apiKeyKey);
    }
  }
}
