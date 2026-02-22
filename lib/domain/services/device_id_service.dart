import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 앱 고유 디바이스 ID 관리.
/// 앱 설치 시 UUID v4를 생성하여 SharedPreferences에 영구 저장.
/// 서버 사용량 제한(디바이스당 50회/일)에 사용됨.
class DeviceIdService {
  static const _key = 'app_device_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    return id;
  }
}
