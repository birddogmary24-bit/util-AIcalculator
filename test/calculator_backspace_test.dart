import 'package:flutter_test/flutter_test.dart';
import 'package:util_ai_calculator/core/utils/calculator_engine.dart';

void main() {
  group('CalculatorEngine Backspace Tests', () {
    late CalculatorEngine engine;

    setUp(() {
      engine = CalculatorEngine();
    });

    test('Single digit backspace resets to 0', () {
      engine.inputDigit('5');
      expect(engine.display, '5');
      engine.backspace();
      expect(engine.display, '0');
    });

    test('Multiple digits backspace removes last digit', () {
      engine.inputDigit('1');
      engine.inputDigit('2');
      engine.inputDigit('3');
      expect(engine.display, '123');
      engine.backspace();
      expect(engine.display, '12');
      engine.backspace();
      expect(engine.display, '1');
      engine.backspace();
      expect(engine.display, '0');
    });

    test('Backspace on decimal number', () {
      engine.inputDigit('1');
      engine.inputDigit('.');
      engine.inputDigit('5');
      expect(engine.display, '1.5');
      engine.backspace();
      expect(engine.display, '1.');
      engine.backspace();
      expect(engine.display, '1');
    });

    test('Backspace after operator cancels operator and restores previous number', () {
      engine.inputDigit('4');
      engine.inputDigit('2');
      engine.inputOperator(CalcOp.add);
      expect(engine.expression, '42 +');
      engine.backspace();
      expect(engine.expression, '');
      expect(engine.display, '42');
    });

    test('Backspace on negative number', () {
      engine.inputDigit('7');
      engine.toggleSign();
      expect(engine.display, '-7');
      engine.backspace();
      expect(engine.display, '0');
    });

    test('Backspace after calculate resets or edits result', () {
      engine.inputDigit('1');
      engine.inputDigit('0');
      engine.inputOperator(CalcOp.add);
      engine.inputDigit('5');
      engine.calculate();
      expect(engine.display, '15');
      engine.backspace();
      expect(engine.display, '1');
    });
  });
}
