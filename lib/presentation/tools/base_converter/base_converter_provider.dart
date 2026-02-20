import 'package:flutter_riverpod/flutter_riverpod.dart';

class BaseConverterState {
  final String input;
  final int fromBase;
  final String binary;
  final String octal;
  final String decimal;
  final String hex;
  final bool isValid;

  const BaseConverterState({
    this.input = '',
    this.fromBase = 10,
    this.binary = '-',
    this.octal = '-',
    this.decimal = '-',
    this.hex = '-',
    this.isValid = true,
  });

  BaseConverterState copyWith({
    String? input,
    int? fromBase,
    String? binary,
    String? octal,
    String? decimal,
    String? hex,
    bool? isValid,
  }) =>
      BaseConverterState(
        input: input ?? this.input,
        fromBase: fromBase ?? this.fromBase,
        binary: binary ?? this.binary,
        octal: octal ?? this.octal,
        decimal: decimal ?? this.decimal,
        hex: hex ?? this.hex,
        isValid: isValid ?? this.isValid,
      );
}

class BaseConverterNotifier extends StateNotifier<BaseConverterState> {
  BaseConverterNotifier() : super(const BaseConverterState());

  void setInput(String v) {
    state = state.copyWith(input: v);
    _convert();
  }

  void setFromBase(int v) {
    state = state.copyWith(fromBase: v);
    _convert();
  }

  void _convert() {
    final raw = state.input.trim();
    if (raw.isEmpty) {
      state = state.copyWith(
        binary: '-',
        octal: '-',
        decimal: '-',
        hex: '-',
        isValid: true,
      );
      return;
    }

    try {
      final value = int.parse(raw, radix: state.fromBase);
      state = state.copyWith(
        binary: value.toRadixString(2),
        octal: value.toRadixString(8),
        decimal: value.toRadixString(10),
        hex: value.toRadixString(16).toUpperCase(),
        isValid: true,
      );
    } catch (_) {
      state = state.copyWith(
        binary: '-',
        octal: '-',
        decimal: '-',
        hex: '-',
        isValid: false,
      );
    }
  }
}

final baseConverterProvider =
    StateNotifierProvider<BaseConverterNotifier, BaseConverterState>(
  (ref) => BaseConverterNotifier(),
);
