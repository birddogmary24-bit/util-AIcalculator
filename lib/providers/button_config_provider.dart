import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  void swapButton(int row, int col, String newButtonId) {
    final updated = state.map((r) => List<String>.from(r)).toList();
    updated[row][col] = newButtonId;
    state = updated;
    _save();
  }

  /// Reset to factory default layout.
  void resetToDefault() {
    state = defaultButtonLayout.map((r) => List<String>.from(r)).toList();
    _save();
  }
}

final buttonConfigProvider =
    StateNotifierProvider<ButtonConfigNotifier, List<List<String>>>((ref) {
  return ButtonConfigNotifier();
});
