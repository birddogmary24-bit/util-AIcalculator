import 'dart:math' as math;
import 'expression_evaluator.dart';

enum CalcOp { add, subtract, multiply, divide, none }

/// Expression-based calculator engine with parentheses support.
///
/// State:
/// - [_tokens]  — accumulated expression tokens (operators + numbers already confirmed)
/// - [_currentInput] — number currently being typed (shown in the big display)
/// - [_openParens] — count of unclosed '('
/// - [_justPressedOp] — last action was an operator / '(' → next digit replaces input
/// - [_justCalculated] — just pressed '=' → next digit starts fresh expression
/// - [_savedExpression] — equation string kept for display after '='
class CalculatorEngine {
  List<String> _tokens = [];
  String _currentInput = '0';
  String _savedExpression = '';
  int _openParens = 0;
  bool _justCalculated = false;
  bool _justPressedOp = false;

  // ── Public getters ────────────────────────────────────────────────────

  String get display => _currentInput;

  String get expression {
    if (_justCalculated && _tokens.isEmpty) return _savedExpression;
    if (_tokens.isEmpty) return '';
    return _tokens.join(' ');
  }

  int get openParens => _openParens;

  bool get isAllClearState =>
      _currentInput == '0' &&
      _tokens.isEmpty &&
      _savedExpression.isEmpty;

  // ── Digit input ───────────────────────────────────────────────────────

  void inputDigit(String digit) {
    if (_justCalculated) {
      // Start a fresh expression after '='
      _currentInput = (digit == '.') ? '0.' : digit;
      _tokens = [];
      _savedExpression = '';
      _openParens = 0;
      _justCalculated = false;
      _justPressedOp = false;
    } else if (_justPressedOp) {
      _currentInput = (digit == '.') ? '0.' : digit;
      _justPressedOp = false;
    } else {
      if (_currentInput == '0' && digit != '.') {
        _currentInput = digit;
      } else if (digit == '.' && _currentInput.contains('.')) {
        return;
      } else if (_currentInput.length < 15) {
        _currentInput += digit;
      }
    }
  }

  // ── Operator input ────────────────────────────────────────────────────

  void inputOperator(CalcOp op) {
    final sym = _opSymbol(op);
    if (_justPressedOp && _tokens.isNotEmpty) {
      // Replace the last operator token (allow changing op without re-entering number)
      _tokens[_tokens.length - 1] = sym;
    } else {
      // Flush current input then append operator
      _tokens.add(_currentInput);
      _tokens.add(sym);
    }
    _justPressedOp = true;
    _justCalculated = false;
  }

  // ── Parenthesis input (smart open / close) ────────────────────────────

  void inputParen() {
    // Close if: there are open parens AND we are not right after an operator
    final shouldClose = _openParens > 0 && !_justPressedOp;

    if (shouldClose) {
      _tokens.add(_currentInput); // flush current number
      _tokens.add(')');
      _openParens--;
      // After closing, treat like an operator pressed (next digit starts fresh number)
      _justPressedOp = true;
      _justCalculated = false;
    } else {
      // Open parenthesis
      // If there's a number already typed and no preceding operator, insert implicit ×
      if (!_justPressedOp && !_justCalculated && _currentInput != '0') {
        _tokens.add(_currentInput);
        _tokens.add('×');
      }
      _tokens.add('(');
      _openParens++;
      _currentInput = '0';
      _justPressedOp = true; // next digit replaces '0'
      _justCalculated = false;
    }
  }

  // ── Calculate ─────────────────────────────────────────────────────────

  void calculate() {
    // 토큰이 없으면 현재 입력값을 그대로 확정 (빈 수식 = 버튼 피드백)
    if (_tokens.isEmpty) {
      _savedExpression = _currentInput;
      _justCalculated = true;
      _justPressedOp = false;
      return;
    }

    // Build final token list for evaluation
    final evalTokens = List<String>.from(_tokens);
    if (!_justPressedOp) evalTokens.add(_currentInput);
    // Auto-close any unclosed parens
    for (int i = 0; i < _openParens; i++) {
      evalTokens.add(')');
    }
    _openParens = 0;

    _savedExpression = evalTokens.join(' ');

    final result = ExpressionEvaluator.evaluate(evalTokens.join(' '));
    _currentInput = _formatResult(result);

    _tokens = [];
    _justCalculated = true;
    _justPressedOp = false;
  }

  // ── Other operations ──────────────────────────────────────────────────

  void percentage() {
    final val = (double.tryParse(_currentInput) ?? 0) / 100;
    _currentInput = _formatResult(val);
  }

  void toggleSign() {
    // 에러 상태나 숫자가 아닌 값에서는 무시
    if (double.tryParse(_currentInput) == null) return;
    if (_currentInput.startsWith('-')) {
      _currentInput = _currentInput.substring(1);
    } else if (_currentInput != '0') {
      _currentInput = '-$_currentInput';
    }
  }

  void squareRoot() {
    final val = double.tryParse(_currentInput) ?? 0;
    if (val < 0) {
      _currentInput = '계산 오류';
      return;
    }
    _savedExpression = '√$_currentInput';
    _currentInput = _formatResult(math.sqrt(val));
    _tokens = [];
    _openParens = 0;
    _justCalculated = true;
    _justPressedOp = false;
  }

  void backspace() {
    if (_justCalculated) {
      if (_currentInput == '계산 오류') {
        _currentInput = '0';
        _savedExpression = '';
        _justCalculated = false;
        return;
      }
      if (_currentInput.length > 1) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        if (_currentInput == '-' || _currentInput.isEmpty) {
          _currentInput = '0';
        }
      } else {
        _currentInput = '0';
      }
      _justCalculated = false;
      return;
    }

    if (_justPressedOp) {
      if (_tokens.isNotEmpty) {
        final lastToken = _tokens.removeLast();
        if (lastToken == '(' && _openParens > 0) {
          _openParens--;
        }
        if (_tokens.isNotEmpty) {
          final prevToken = _tokens.removeLast();
          if (double.tryParse(prevToken) != null || prevToken == '0') {
            _currentInput = prevToken;
          } else {
            _tokens.add(prevToken);
          }
        }
      }
      _justPressedOp = false;
      return;
    }

    if (_currentInput.length > 1) {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      if (_currentInput == '-' || _currentInput.isEmpty) {
        _currentInput = '0';
      }
    } else {
      _currentInput = '0';
    }
  }

  void clear() {
    _currentInput = '0';
    _justPressedOp = false;
    _justCalculated = false;
  }

  void allClear() {
    _currentInput = '0';
    _tokens = [];
    _savedExpression = '';
    _openParens = 0;
    _justCalculated = false;
    _justPressedOp = false;
  }

  void setResult(double value, String expr) {
    _currentInput = _formatResult(value);
    _savedExpression = expr;
    _tokens = [];
    _openParens = 0;
    _justCalculated = true;
    _justPressedOp = false;
  }

  // ── Private helpers ───────────────────────────────────────────────────

  String _opSymbol(CalcOp op) {
    switch (op) {
      case CalcOp.add:
        return '+';
      case CalcOp.subtract:
        return '−';
      case CalcOp.multiply:
        return '×';
      case CalcOp.divide:
        return '÷';
      case CalcOp.none:
        return '';
    }
  }

  String _formatResult(double n) {
    if (n.isInfinite || n.isNaN) return '계산 오류';
    if (n == n.truncateToDouble()) return n.toInt().toString();
    // 소수점 10자리로 반올림하여 부동소수점 오류 제거 (0.1+0.2=0.3)
    final rounded = double.parse(n.toStringAsFixed(10));
    if (rounded == rounded.truncateToDouble()) return rounded.toInt().toString();
    final s = rounded.toString();
    if (s.length > 12) {
      // 유효숫자 10자리로 표현 (trailing zero 제거)
      final precise = rounded.toStringAsPrecision(10);
      // scientific notation 포함 여부 처리
      if (precise.contains('e') || precise.contains('E')) return precise;
      return precise
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}
