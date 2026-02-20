/// Shunting-yard expression evaluator.
/// Supports: + − × ÷ (display symbols) or + - * / (ASCII), parentheses.
class ExpressionEvaluator {
  static int _prec(String op) {
    switch (op) {
      case '+':
      case '−':
      case '-':
        return 1;
      case '×':
      case '÷':
      case '*':
      case '/':
        return 2;
      default:
        return 0;
    }
  }

  static bool _isOp(String s) => '+-−×÷*/'.contains(s) && s.length == 1;

  /// Tokenize: e.g. "(15+5)×10" → ['(', '15', '+', '5', ')', '×', '10']
  static List<String> _tokenize(String expr) {
    final tokens = <String>[];
    final buf = StringBuffer();

    for (final ch in expr.runes.map(String.fromCharCode)) {
      if (ch == ' ') {
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
        continue;
      }
      if ('0123456789.'.contains(ch)) {
        buf.write(ch);
      } else {
        if (buf.isNotEmpty) {
          tokens.add(buf.toString());
          buf.clear();
        }
        if ('()+-−×÷*/'.contains(ch)) tokens.add(ch);
      }
    }
    if (buf.isNotEmpty) tokens.add(buf.toString());
    return tokens;
  }

  /// Shunting-yard → postfix (RPN)
  static List<String> _toRpn(List<String> tokens) {
    final output = <String>[];
    final ops = <String>[];

    for (int i = 0; i < tokens.length; i++) {
      final tok = tokens[i];
      final num = double.tryParse(tok);

      if (num != null) {
        output.add(tok);
      } else if (_isOp(tok)) {
        // Detect unary minus: first token, or after '(' or operator
        final isUnary = (tok == '-' || tok == '−') &&
            (i == 0 ||
                tokens[i - 1] == '(' ||
                _isOp(tokens[i - 1]));
        if (isUnary) {
          output.add('0'); // 0 − x makes unary work
        }
        while (ops.isNotEmpty &&
            ops.last != '(' &&
            _prec(ops.last) >= _prec(tok)) {
          output.add(ops.removeLast());
        }
        ops.add(tok);
      } else if (tok == '(') {
        ops.add(tok);
      } else if (tok == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        if (ops.isNotEmpty) ops.removeLast(); // pop '('
      }
    }
    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }
    return output;
  }

  /// Evaluate RPN list
  static double _evalRpn(List<String> rpn) {
    final stack = <double>[];
    for (final tok in rpn) {
      final num = double.tryParse(tok);
      if (num != null) {
        stack.add(num);
      } else if (_isOp(tok) && stack.length >= 2) {
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (tok) {
          case '+':
            stack.add(a + b);
          case '-':
          case '−':
            stack.add(a - b);
          case '*':
          case '×':
            stack.add(a * b);
          case '/':
          case '÷':
            stack.add(b == 0 ? double.infinity : a / b);
        }
      }
    }
    return stack.isNotEmpty ? stack.last : 0;
  }

  /// Evaluate an expression string. Returns [double.nan] on parse error.
  static double evaluate(String expr) {
    try {
      final tokens = _tokenize(expr);
      if (tokens.isEmpty) return 0;
      final rpn = _toRpn(tokens);
      return _evalRpn(rpn);
    } catch (_) {
      return double.nan;
    }
  }
}
