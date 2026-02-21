import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/region.dart';
import '../domain/models/button_definition.dart';

const _storageKey = 'button_layout';

class ButtonConfigNotifier extends StateNotifier<List<List<String>>> {
  ButtonConfigNotifier()
      : super(defaultButtonLayout.map((r) => List<String>.from(r)).toList()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as List;
        final layout = decoded
            .map((row) => (row as List).map((e) => e as String).toList())
            .toList();
        if (layout.length == 5 && layout.every((r) => r.length == 4)) {
          state = layout;
        }
      } catch (_) {
        // Corrupted data — keep default
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state));
  }

  /// Replace the button at [row],[col] with [newButtonId].
  Future<void> swapButton(int row, int col, String newButtonId) async {
    final updated = state.map((r) => List<String>.from(r)).toList();
    updated[row][col] = newButtonId;
    state = updated;
    await _save();
  }

  /// Reset to factory default layout.
  Future<void> resetToDefault() async {
    state = defaultButtonLayout.map((r) => List<String>.from(r)).toList();
    await _save();
  }
}

final buttonConfigProvider =
    StateNotifierProvider<ButtonConfigNotifier, List<List<String>>>((ref) {
  return ButtonConfigNotifier();
});

// ── Utility row configuration ─────────────────────────────────────────────────

const _utilityStorageKey = 'utility_buttons';
const utilitySlotCount = 5;

/// Legacy constant for backward compatibility.
const utilityPlaceholders = ['고급계산', '설정1', '설정2', '설정3', '설정4'];

/// Returns localized utility row placeholder labels based on region.
List<String> getUtilityPlaceholders(RegionMode region) {
  final s = AppStrings.of(region);
  final slotLabel = s['util_slot']!;
  return [
    s['util_advanced']!,
    '$slotLabel 1',
    '$slotLabel 2',
    '$slotLabel 3',
    '$slotLabel 4',
  ];
}

class UtilityButtonConfigNotifier extends StateNotifier<List<String?>> {
  UtilityButtonConfigNotifier() : super(List.filled(utilitySlotCount, null)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_utilityStorageKey);
    if (json != null) {
      try {
        final decoded = jsonDecode(json) as List;
        if (decoded.length == utilitySlotCount) {
          state = decoded.map((e) => e as String?).toList();
        }
      } catch (_) {
        // Corrupted — keep default
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_utilityStorageKey, jsonEncode(state));
  }

  Future<void> setButton(int index, String buttonId) async {
    final updated = List<String?>.from(state);
    updated[index] = buttonId;
    state = updated;
    await _save();
  }

  Future<void> clearButton(int index) async {
    final updated = List<String?>.from(state);
    updated[index] = null;
    state = updated;
    await _save();
  }

  Future<void> resetAll() async {
    state = List.filled(utilitySlotCount, null);
    await _save();
  }
}

final utilityButtonConfigProvider =
    StateNotifierProvider<UtilityButtonConfigNotifier, List<String?>>((ref) {
  return UtilityButtonConfigNotifier();
});
