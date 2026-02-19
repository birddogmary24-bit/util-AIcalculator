enum CalcOp { add, subtract, multiply, divide, none }

class CalculatorEngine {
  double _operand1 = 0;
  double _operand2 = 0;
  CalcOp _pendingOp = CalcOp.none;
  String _displayInput = '0';
  bool _justCalculated = false;
  bool _justPressedOp = false;
  String _expressionStr = '';

  String get display => _displayInput;
  String get expression => _expressionStr;

  void inputDigit(String digit) {
    if (_justCalculated) {
      _displayInput = digit;
      _justCalculated = false;
      _justPressedOp = false;
    } else if (_justPressedOp) {
      _displayInput = digit;
      _justPressedOp = false;
    } else {
      if (_displayInput == '0' && digit != '.') {
        _displayInput = digit;
      } else if (digit == '.' && _displayInput.contains('.')) {
        return;
      } else if (_displayInput.length < 15) {
        _displayInput += digit;
      }
    }
  }

  void inputOperator(CalcOp op) {
    if (!_justPressedOp && !_justCalculated) {
      _operand1 = _currentValue;
    } else if (!_justPressedOp) {
      _operand1 = _currentValue;
    }
    _pendingOp = op;
    _justPressedOp = true;
    _justCalculated = false;
    _expressionStr = '${_formatNumber(_operand1)} ${_opSymbol(op)}';
  }

  void calculate() {
    if (_pendingOp == CalcOp.none) return;
    _operand2 = _currentValue;
    final result = _applyOp(_operand1, _operand2, _pendingOp);
    _expressionStr =
        '${_formatNumber(_operand1)} ${_opSymbol(_pendingOp)} ${_formatNumber(_operand2)}';
    _displayInput = _formatResult(result);
    _operand1 = result;
    _pendingOp = CalcOp.none;
    _justCalculated = true;
    _justPressedOp = false;
  }

  void percentage() {
    final val = _currentValue / 100;
    _displayInput = _formatResult(val);
    _justCalculated = false;
    _justPressedOp = false;
  }

  void toggleSign() {
    if (_displayInput.startsWith('-')) {
      _displayInput = _displayInput.substring(1);
    } else if (_displayInput != '0') {
      _displayInput = '-$_displayInput';
    }
  }

  void clear() {
    _displayInput = '0';
    _justPressedOp = false;
    _justCalculated = false;
  }

  void allClear() {
    _displayInput = '0';
    _operand1 = 0;
    _operand2 = 0;
    _pendingOp = CalcOp.none;
    _justCalculated = false;
    _justPressedOp = false;
    _expressionStr = '';
  }

  void setResult(double value, String expr) {
    _displayInput = _formatResult(value);
    _expressionStr = expr;
    _operand1 = value;
    _pendingOp = CalcOp.none;
    _justCalculated = true;
    _justPressedOp = false;
  }

  bool get hasOperator => _pendingOp != CalcOp.none;
  bool get isAllClearState =>
      _displayInput == '0' && _pendingOp == CalcOp.none && _expressionStr.isEmpty;

  double get _currentValue => double.tryParse(_displayInput) ?? 0;

  double _applyOp(double a, double b, CalcOp op) {
    switch (op) {
      case CalcOp.add:
        return a + b;
      case CalcOp.subtract:
        return a - b;
      case CalcOp.multiply:
        return a * b;
      case CalcOp.divide:
        return b == 0 ? double.infinity : a / b;
      case CalcOp.none:
        return a;
    }
  }

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

  String _formatNumber(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toString();
  }

  String _formatResult(double n) {
    if (n.isInfinite) return '계산 오류';
    if (n.isNaN) return '0';
    if (n == n.truncateToDouble()) return n.toInt().toString();
    final s = n.toString();
    if (s.length > 12) return n.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }
}
