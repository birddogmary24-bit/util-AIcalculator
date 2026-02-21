import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/calculator_engine.dart';
import '../../core/utils/expression_evaluator.dart';
import '../../domain/services/gemini_service.dart';
import '../../domain/services/usage_limiter.dart';
import '../../data/repositories/history_repository.dart';

class DisplayLine {
  final String expression;
  final String result;
  final bool isAi;
  const DisplayLine({required this.expression, required this.result, this.isAi = false});
}

class CalculatorState {
  final String display;
  final String expression;
  final bool isAiLoading;
  final int openParens;
  final List<DisplayLine> displayHistory;

  const CalculatorState({
    this.display = '0',
    this.expression = '',
    this.isAiLoading = false,
    this.openParens = 0,
    this.displayHistory = const [],
  });

  CalculatorState copyWith({
    String? display,
    String? expression,
    bool? isAiLoading,
    int? openParens,
    List<DisplayLine>? displayHistory,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      expression: expression ?? this.expression,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      openParens: openParens ?? this.openParens,
      displayHistory: displayHistory ?? this.displayHistory,
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
    if (input.trim().isEmpty) return;

    // 수식 패턴이면 Gemini 없이 자체 계산 (예: "35+3", "100*5", "(3+4)*2")
    final directResult = ExpressionEvaluator.evaluate(input);
    if (!directResult.isNaN) {
      _engine.setResult(directResult, input);
      final history = [...state.displayHistory];
      history.add(DisplayLine(expression: input, result: _engine.display));
      if (history.length > 10) history.removeAt(0);
      state = state.copyWith(
        display: _engine.display,
        expression: input,
        displayHistory: history,
      );
      _saveHistory(input, directResult, 'direct');
      return;
    }

    final service = _ref.read(geminiServiceProvider);
    if (service == null) return;

    state = state.copyWith(isAiLoading: true);
    try {
      await _ref.read(usageLimiterProvider).checkAndIncrement();
      final result = await service.parseNaturalLanguage(input);

      if (result.isError) {
        debugPrint('[CalculatorProvider] parseNaturalLanguage error: ${result.errorMessage}');
        state = state.copyWith(display: '계산 오류', isAiLoading: false);
        return;
      }

      _engine.setResult(result.value, result.expression);
      final history = [...state.displayHistory];
      history.add(DisplayLine(
        expression: result.expression,
        result: _engine.display,
        isAi: true,
      ));
      if (history.length > 10) history.removeAt(0);
      state = state.copyWith(
        display: _engine.display,
        expression: result.expression,
        isAiLoading: false,
        displayHistory: history,
      );
      _saveHistory(result.expression, result.value, 'nlp');
    } on LimitExceededException {
      state = state.copyWith(
        display: 'AI 한도 초과',
        isAiLoading: false,
      );
    } catch (e, st) {
      debugPrint('[CalculatorProvider] parseNaturalLanguage exception: $e\n$st');
      state = state.copyWith(display: '계산 오류', isAiLoading: false);
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
