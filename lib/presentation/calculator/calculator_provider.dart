import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/calculator_engine.dart';
import '../../data/repositories/history_repository.dart';
import '../../providers/config_provider.dart';

class DisplayLine {
  final String expression;
  final String result;
  final bool isAi;
  const DisplayLine({required this.expression, required this.result, this.isAi = false});
}

class CalculatorState {
  final String display;
  final String expression;
  final int openParens;
  final List<DisplayLine> displayHistory;
  final bool isAiLoading;

  const CalculatorState({
    this.display = '0',
    this.expression = '',
    this.openParens = 0,
    this.displayHistory = const [],
    this.isAiLoading = false,
  });

  CalculatorState copyWith({
    String? display,
    String? expression,
    int? openParens,
    List<DisplayLine>? displayHistory,
    bool? isAiLoading,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      expression: expression ?? this.expression,
      openParens: openParens ?? this.openParens,
      displayHistory: displayHistory ?? this.displayHistory,
      isAiLoading: isAiLoading ?? this.isAiLoading,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  final CalculatorEngine _engine = CalculatorEngine();
  final Ref _ref;

  CalculatorNotifier(this._ref) : super(const CalculatorState());

  void inputDigit(String digit) {
    _engine.inputDigit(digit);
    state = state.copyWith(
      display: _engine.display,
      expression: _engine.expression,
    );
  }

  void inputOperator(CalcOp op) {
    _engine.inputOperator(op);
    state = state.copyWith(
      display: _engine.display,
      expression: _engine.expression,
      openParens: _engine.openParens,
    );
  }

  void inputParen() {
    _engine.inputParen();
    state = state.copyWith(
      display: _engine.display,
      expression: _engine.expression,
      openParens: _engine.openParens,
    );
  }

  void calculate() {
    _engine.calculate();
    final expr = _engine.expression;
    final resultDisplay = _engine.display;
    final result = double.tryParse(resultDisplay) ?? 0;

    // Push to LCD display history
    final history = [...state.displayHistory];
    if (expr.isNotEmpty) {
      history.add(DisplayLine(expression: expr, result: resultDisplay));
      // Keep max 10 lines
      if (history.length > 10) history.removeAt(0);
    }

    state = state.copyWith(
      display: resultDisplay,
      expression: expr,
      openParens: 0,
      displayHistory: history,
    );
    _saveHistory(expr, result, 'calculator');
  }

  void percentage() {
    _engine.percentage();
    state = state.copyWith(display: _engine.display);
  }

  void toggleSign() {
    _engine.toggleSign();
    state = state.copyWith(display: _engine.display);
  }

  void backspace() {
    _engine.backspace();
    state = state.copyWith(
      display: _engine.display,
      expression: _engine.expression,
      openParens: _engine.openParens,
    );
  }

  void clear() {
    _engine.clear();
    state = state.copyWith(display: _engine.display);
  }

  void allClear() {
    _engine.allClear();
    state = state.copyWith(
      display: _engine.display,
      expression: _engine.expression,
      openParens: 0,
      displayHistory: const [],
    );
  }

  void squareRoot() {
    _engine.squareRoot();
    state = state.copyWith(
      display: _engine.display,
      expression: _engine.expression,
    );
  }

  void loadFromHistory(String expression, double result) {
    _engine.setResult(result, expression);
    state = state.copyWith(
      display: _engine.display,
      expression: expression,
    );
  }

  bool get isAllClear => _engine.isAllClearState;

  Future<void> parseNaturalLanguage(String input) async {
    final service = _ref.read(aiServiceProvider);
    if (service == null) return;
    state = state.copyWith(isAiLoading: true);
    try {
      final result = await service.parseNaturalLanguage(input);
      if (result.isError) {
        state = state.copyWith(isAiLoading: false);
        return;
      }
      final history = [...state.displayHistory];
      history.add(DisplayLine(expression: input, result: result.value.toString(), isAi: true));
      if (history.length > 10) history.removeAt(0);
      _engine.setResult(result.value, result.expression);
      state = state.copyWith(
        display: _engine.display,
        expression: result.expression,
        isAiLoading: false,
        displayHistory: history,
      );
      _saveHistory(result.expression, result.value, 'ai');
    } catch (e, st) {
      debugPrint('[CalculatorProvider] parseNaturalLanguage error: $e\n$st');
      state = state.copyWith(isAiLoading: false);
    }
  }

  Future<void> _saveHistory(
      String expression, double result, String source) async {
    try {
      await _ref.read(historyRepositoryProvider).save(
            expression: expression,
            result: result,
            source: source,
          );
      await _ref.read(historyNotifierProvider.notifier).refresh();
    } catch (e, st) {
      debugPrint('[CalculatorProvider] _saveHistory error: $e\n$st');
    }
  }
}

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier(ref);
});
