import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/calculator_engine.dart';
import '../../domain/services/gemini_service.dart';
import '../../data/repositories/history_repository.dart';

class DisplayLine {
  final String expression;
  final String result;
  const DisplayLine({required this.expression, required this.result});
}

class CalculatorState {
  final String display;
  final String expression;
  final String? contextTip;
  final bool isAiLoading;
  final bool showTip;
  final int openParens;
  final List<DisplayLine> displayHistory;

  const CalculatorState({
    this.display = '0',
    this.expression = '',
    this.contextTip,
    this.isAiLoading = false,
    this.showTip = false,
    this.openParens = 0,
    this.displayHistory = const [],
  });

  CalculatorState copyWith({
    String? display,
    String? expression,
    String? contextTip,
    bool? isAiLoading,
    bool? showTip,
    int? openParens,
    List<DisplayLine>? displayHistory,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      expression: expression ?? this.expression,
      contextTip: contextTip ?? this.contextTip,
      isAiLoading: isAiLoading ?? this.isAiLoading,
      showTip: showTip ?? this.showTip,
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
      showTip: false,
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
      showTip: false,
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
      showTip: false,
      openParens: 0,
      displayHistory: history,
    );
    _saveHistory(expr, result, 'calculator');
    _fetchContextTip(expr, result);
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
    state = state.copyWith(display: _engine.display, showTip: false);
  }

  void allClear() {
    _engine.allClear();
    state = state.copyWith(
      display: _engine.display,
      expression: _engine.expression,
      showTip: false,
      contextTip: null,
      openParens: 0,
      displayHistory: const [],
    );
  }

  void squareRoot() {
    _engine.squareRoot();
    state = state.copyWith(
      display: _engine.display,
      expression: _engine.expression,
      showTip: false,
    );
  }

  void dismissTip() {
    state = state.copyWith(showTip: false);
  }

  void loadFromHistory(String expression, double result) {
    _engine.setResult(result, expression);
    state = state.copyWith(
      display: _engine.display,
      expression: expression,
      showTip: false,
    );
  }

  bool get isAllClear => _engine.isAllClearState;

  Future<void> parseNaturalLanguage(String input) async {
    if (input.trim().isEmpty) return;
    final service = _ref.read(geminiServiceProvider);
    if (service == null) return;

    state = state.copyWith(isAiLoading: true, showTip: false);
    try {
      final result = await service.parseNaturalLanguage(input);
      _engine.setResult(result.value, result.expression);
      final history = [...state.displayHistory];
      history.add(DisplayLine(
        expression: result.expression,
        result: _engine.display,
      ));
      if (history.length > 10) history.removeAt(0);
      state = state.copyWith(
        display: _engine.display,
        expression: result.expression,
        contextTip: result.explanation,
        showTip: result.explanation.isNotEmpty,
        isAiLoading: false,
        displayHistory: history,
      );
      _saveHistory(result.expression, result.value, 'nlp');
    } catch (_) {
      state = state.copyWith(isAiLoading: false);
    }
  }

  Future<void> _fetchContextTip(String expression, double result) async {
    if (expression.isEmpty || result == 0) return;
    final service = _ref.read(geminiServiceProvider);
    if (service == null) return;

    try {
      final tip = await service.interpretContext(expression, result);
      if (tip.isNotEmpty) {
        state = state.copyWith(contextTip: tip, showTip: true);
      }
    } catch (_) {
      // Non-blocking: silently ignore
    }
  }

  void _saveHistory(String expression, double result, String source) {
    try {
      final repo = _ref.read(historyRepositoryProvider);
      repo.save(expression: expression, result: result, source: source);
      _ref.read(historyNotifierProvider.notifier).refresh();
      _generateLabel(expression, result);
    } catch (_) {}
  }

  Future<void> _generateLabel(String expression, double result) async {
    final service = _ref.read(geminiServiceProvider);
    if (service == null) return;
    try {
      final repo = _ref.read(historyRepositoryProvider);
      final label = await service.generateLabel(expression, result);
      await repo.updateLatestLabel(label);
      _ref.read(historyNotifierProvider.notifier).refresh();
    } catch (_) {}
  }
}

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier(ref);
});
