import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Category enum ────────────────────────────────────────────────────────────

enum UnitCategory { length, weight, area, volume, temperature, speed }

// ── Unit item model ──────────────────────────────────────────────────────────

class UnitItem {
  final String id;
  final String label;
  final String symbol;
  final double toBase; // multiply by this to convert to the base unit
  const UnitItem(this.id, this.label, this.symbol, this.toBase);
}

// ── Unit data ────────────────────────────────────────────────────────────────

const Map<UnitCategory, String> categoryLabels = {
  UnitCategory.length: '길이',
  UnitCategory.weight: '무게',
  UnitCategory.area: '넓이',
  UnitCategory.volume: '부피',
  UnitCategory.temperature: '온도',
  UnitCategory.speed: '속도',
};

const Map<UnitCategory, List<UnitItem>> unitData = {
  // Length — base: m
  UnitCategory.length: [
    UnitItem('mm', '밀리미터', 'mm', 0.001),
    UnitItem('cm', '센티미터', 'cm', 0.01),
    UnitItem('m', '미터', 'm', 1),
    UnitItem('km', '킬로미터', 'km', 1000),
    UnitItem('inch', '인치', 'in', 0.0254),
    UnitItem('ft', '피트', 'ft', 0.3048),
    UnitItem('yard', '야드', 'yd', 0.9144),
    UnitItem('mile', '마일', 'mi', 1609.344),
  ],

  // Weight — base: g
  UnitCategory.weight: [
    UnitItem('mg', '밀리그램', 'mg', 0.001),
    UnitItem('g', '그램', 'g', 1),
    UnitItem('kg', '킬로그램', 'kg', 1000),
    UnitItem('ton', '톤', 't', 1000000),
    UnitItem('oz', '온스', 'oz', 28.3495),
    UnitItem('lb', '파운드', 'lb', 453.592),
    UnitItem('geun', '근', '근', 600),
  ],

  // Area — base: m²
  UnitCategory.area: [
    UnitItem('sqm', '제곱미터', '\u33A1', 1),
    UnitItem('sqkm', '제곱킬로미터', '\u33A2', 1000000),
    UnitItem('pyeong', '평', '평', 3.305785),
    UnitItem('acre', '에이커', 'ac', 4046.8564),
    UnitItem('ha', '헥타르', 'ha', 10000),
  ],

  // Volume — base: mL
  UnitCategory.volume: [
    UnitItem('mL', '밀리리터', 'mL', 1),
    UnitItem('L', '리터', 'L', 1000),
    UnitItem('cbm', '세제곱미터', '\u33A5', 1000000),
    UnitItem('gallon', '갤런', 'gal', 3785.41),
    UnitItem('fl_oz', '액량온스', 'fl oz', 29.5735),
    UnitItem('cup', '컵', '컵', 200),
  ],

  // Temperature — special handling (toBase not used)
  UnitCategory.temperature: [
    UnitItem('C', '섭씨', '\u2103', 1),
    UnitItem('F', '화씨', '\u2109', 1),
    UnitItem('K', '켈빈', 'K', 1),
  ],

  // Speed — base: m/s
  UnitCategory.speed: [
    UnitItem('ms', '미터/초', 'm/s', 1),
    UnitItem('kmh', '킬로미터/시', 'km/h', 0.277778),
    UnitItem('mph', '마일/시', 'mph', 0.44704),
    UnitItem('knot', '노트', 'kn', 0.514444),
  ],
};

// ── State ────────────────────────────────────────────────────────────────────

class UnitState {
  final UnitCategory category;
  final String fromUnitId;
  final String toUnitId;
  final double inputValue;
  final double? result;

  const UnitState({
    this.category = UnitCategory.length,
    this.fromUnitId = 'cm',
    this.toUnitId = 'm',
    this.inputValue = 0,
    this.result,
  });

  UnitState copyWith({
    UnitCategory? category,
    String? fromUnitId,
    String? toUnitId,
    double? inputValue,
    double? result,
  }) =>
      UnitState(
        category: category ?? this.category,
        fromUnitId: fromUnitId ?? this.fromUnitId,
        toUnitId: toUnitId ?? this.toUnitId,
        inputValue: inputValue ?? this.inputValue,
        result: result ?? this.result,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class UnitNotifier extends StateNotifier<UnitState> {
  UnitNotifier() : super(const UnitState());

  void setCategory(UnitCategory cat) {
    final units = unitData[cat]!;
    state = state.copyWith(
      category: cat,
      fromUnitId: units[0].id,
      toUnitId: units.length > 1 ? units[1].id : units[0].id,
      inputValue: 0,
      result: null,
    );
  }

  void setFromUnit(String id) {
    state = state.copyWith(fromUnitId: id);
    _convert();
  }

  void setToUnit(String id) {
    state = state.copyWith(toUnitId: id);
    _convert();
  }

  void setInputValue(double v) {
    state = state.copyWith(inputValue: v);
    _convert();
  }

  void swapUnits() {
    state = state.copyWith(
      fromUnitId: state.toUnitId,
      toUnitId: state.fromUnitId,
    );
    _convert();
  }

  void _convert() {
    final units = unitData[state.category]!;
    final from = units.firstWhere((u) => u.id == state.fromUnitId);
    final to = units.firstWhere((u) => u.id == state.toUnitId);
    final v = state.inputValue;

    double result;

    if (state.category == UnitCategory.temperature) {
      result = _convertTemperature(v, from.id, to.id);
    } else {
      // Generic: value * fromBase / toBase
      result = v * from.toBase / to.toBase;
    }

    state = state.copyWith(result: result);
  }

  double _convertTemperature(double value, String fromId, String toId) {
    if (fromId == toId) return value;

    // Convert to Celsius first
    double celsius;
    switch (fromId) {
      case 'C':
        celsius = value;
      case 'F':
        celsius = (value - 32) * 5 / 9;
      case 'K':
        celsius = value - 273.15;
      default:
        celsius = value;
    }

    // Convert from Celsius to target
    switch (toId) {
      case 'C':
        return celsius;
      case 'F':
        return celsius * 9 / 5 + 32;
      case 'K':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final unitProvider = StateNotifierProvider<UnitNotifier, UnitState>(
  (ref) => UnitNotifier(),
);
