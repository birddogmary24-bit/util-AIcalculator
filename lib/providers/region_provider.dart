import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/region.dart';

final regionProvider = StateNotifierProvider<RegionNotifier, RegionMode>(
  (ref) => RegionNotifier(),
);

class RegionNotifier extends StateNotifier<RegionMode> {
  RegionNotifier() : super(RegionMode.kr) {
    _load();
  }

  static const _key = 'region_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'kr') state = RegionMode.kr;
    if (value == 'global') state = RegionMode.global;
  }

  Future<void> setRegion(RegionMode region) async {
    state = region;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      region == RegionMode.kr ? 'kr' : 'global',
    );
  }
}

final isOnboardedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('region_mode');
});
