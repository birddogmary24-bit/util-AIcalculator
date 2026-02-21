import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/region.dart';

// ── Category enum ────────────────────────────────────────────────────────────

enum UnitCategory { length, weight, area, volume, temperature, speed }

// ── Unit item model ──────────────────────────────────────────────────────────

class UnitItem {
  final String id;
  final String labelKr;
  final String labelEn;
  final String symbol;
  final double toBase; // multiply by this to convert to the base unit
  const UnitItem(this.id, this.labelKr, this.labelEn, this.symbol, this.toBase);

  String label(RegionMode region) =>
      region == RegionMode.kr ? labelKr : labelEn;
}

// ── Unit data ────────────────────────────────────────────────────────────────

const Map<RegionMode, Map<UnitCategory, String>> categoryLabelsMap = {
  RegionMode.kr: {
    UnitCategory.length: '길이',
    UnitCategory.weight: '무게',
    UnitCategory.area: '넓이',
    UnitCategory.volume: '부피',
    UnitCategory.temperature: '온도',
    UnitCategory.speed: '속도',
  },
  RegionMode.global: {
    UnitCategory.length: 'Length',
    UnitCategory.weight: 'Weight',
    UnitCategory.area: 'Area',
    UnitCategory.volume: 'Volume',
    UnitCategory.temperature: 'Temperature',
    UnitCategory.speed: 'Speed',
  },
};

/// Shortcut for backward-compatibility (kr labels)
const Map<UnitCategory, String> categoryLabels = {
  UnitCategory.length: '길이',
  UnitCategory.weight: '무게',
  UnitCategory.area: '넓이',
  UnitCategory.volume: '부피',
  UnitCategory.temperature: '온도',
  UnitCategory.speed: '속도',
};

String categoryLabel(UnitCategory cat, RegionMode region) {
  return categoryLabelsMap[region]?[cat] ?? categoryLabels[cat]!;
}

const Map<UnitCategory, List<UnitItem>> unitData = {
  // Length — base: m
  UnitCategory.length: [
    UnitItem('mm', '밀리미터', 'Millimeter', 'mm', 0.001),
    UnitItem('cm', '센티미터', 'Centimeter', 'cm', 0.01),
    UnitItem('m', '미터', 'Meter', 'm', 1),
    UnitItem('km', '킬로미터', 'Kilometer', 'km', 1000),
    UnitItem('inch', '인치', 'Inch', 'in', 0.0254),
    UnitItem('ft', '피트', 'Foot', 'ft', 0.3048),
    UnitItem('yard', '야드', 'Yard', 'yd', 0.9144),
    UnitItem('mile', '마일', 'Mile', 'mi', 1609.344),
  ],

  // Weight — base: g
  UnitCategory.weight: [
    UnitItem('mg', '밀리그램', 'Milligram', 'mg', 0.001),
    UnitItem('g', '그램', 'Gram', 'g', 1),
    UnitItem('kg', '킬로그램', 'Kilogram', 'kg', 1000),
    UnitItem('ton', '톤', 'Ton', 't', 1000000),
    UnitItem('oz', '온스', 'Ounce', 'oz', 28.3495),
    UnitItem('lb', '파운드', 'Pound', 'lb', 453.592),
    UnitItem('geun', '근', 'Geun', '근', 600),
  ],

  // Area — base: m²
  UnitCategory.area: [
    UnitItem('sqm', '제곱미터', 'Square Meter', '\u33A1', 1),
    UnitItem('sqkm', '제곱킬로미터', 'Square Kilometer', '\u33A2', 1000000),
    UnitItem('pyeong', '평', 'Pyeong', '평', 3.305785),
    UnitItem('acre', '에이커', 'Acre', 'ac', 4046.8564),
    UnitItem('ha', '헥타르', 'Hectare', 'ha', 10000),
  ],

  // Volume — base: mL
  UnitCategory.volume: [
    UnitItem('mL', '밀리리터', 'Milliliter', 'mL', 1),
    UnitItem('L', '리터', 'Liter', 'L', 1000),
    UnitItem('cbm', '세제곱미터', 'Cubic Meter', '\u33A5', 1000000),
    UnitItem('gallon', '갤런', 'Gallon', 'gal', 3785.41),
    UnitItem('fl_oz', '액량온스', 'Fluid Ounce', 'fl oz', 29.5735),
    UnitItem('cup', '컵', 'Cup', '컵', 200),
  ],

  // Temperature — special handling (toBase not used)
  UnitCategory.temperature: [
    UnitItem('C', '섭씨', 'Celsius', '\u2103', 1),
    UnitItem('F', '화씨', 'Fahrenheit', '\u2109', 1),
    UnitItem('K', '켈빈', 'Kelvin', 'K', 1),
  ],

  // Speed — base: m/s
  UnitCategory.speed: [
    UnitItem('ms', '미터/초', 'Meters/sec', 'm/s', 1),
    UnitItem('kmh', '킬로미터/시', 'Kilometers/hr', 'km/h', 0.277778),
    UnitItem('mph', '마일/시', 'Miles/hr', 'mph', 0.44704),
    UnitItem('knot', '노트', 'Knot', 'kn', 0.514444),
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
