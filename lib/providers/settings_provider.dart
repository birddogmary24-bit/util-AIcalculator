import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/region.dart';

enum AppCurrency { krw, usd, eur, gbp }

enum UnitSystem { metric, imperial }

enum DateFormatOption { yyyymmdd, mmddyyyy, ddmmyyyy }

class SettingsState {
  final AppCurrency currency;
  final UnitSystem units;
  final DateFormatOption dateFormat;

  const SettingsState({
    this.currency = AppCurrency.krw,
    this.units = UnitSystem.metric,
    this.dateFormat = DateFormatOption.yyyymmdd,
  });

  SettingsState copyWith({
    AppCurrency? currency,
    UnitSystem? units,
    DateFormatOption? dateFormat,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      units: units ?? this.units,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }

  Map<String, String> toJson() {
    return {
      'currency': currency.name,
      'units': units.name,
      'dateFormat': dateFormat.name,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      currency: AppCurrency.values.firstWhere(
        (e) => e.name == json['currency'],
        orElse: () => AppCurrency.krw,
      ),
      units: UnitSystem.values.firstWhere(
        (e) => e.name == json['units'],
        orElse: () => UnitSystem.metric,
      ),
      dateFormat: DateFormatOption.values.firstWhere(
        (e) => e.name == json['dateFormat'],
        orElse: () => DateFormatOption.yyyymmdd,
      ),
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _key = 'app_settings';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        state = SettingsState.fromJson(json);
      } catch (_) {
        // Corrupted data — keep defaults
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = state.copyWith(currency: currency);
    await _persist();
  }

  Future<void> setUnits(UnitSystem units) async {
    state = state.copyWith(units: units);
    await _persist();
  }

  Future<void> setDateFormat(DateFormatOption dateFormat) async {
    state = state.copyWith(dateFormat: dateFormat);
    await _persist();
  }

  Future<void> applyRegionDefaults(RegionMode region) async {
    switch (region) {
      case RegionMode.kr:
        state = const SettingsState(
          currency: AppCurrency.krw,
          units: UnitSystem.metric,
          dateFormat: DateFormatOption.yyyymmdd,
        );
        break;
      case RegionMode.global:
        state = const SettingsState(
          currency: AppCurrency.usd,
          units: UnitSystem.metric,
          dateFormat: DateFormatOption.mmddyyyy,
        );
        break;
    }
    await _persist();
  }
}
