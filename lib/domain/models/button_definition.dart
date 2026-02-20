import '../../presentation/calculator/widgets/calc_button.dart';

/// Action type for a calculator button.
enum ButtonAction { digit, operator, function, calculate, clear, navigate, special }

/// Definition of a single calculator button (both built-in and tool shortcuts).
class CalcButtonDef {
  final String id;
  final String label;
  final CalcButtonType type;
  final ButtonAction action;
  final String? param; // digit value, operator type, route path, etc.

  const CalcButtonDef({
    required this.id,
    required this.label,
    required this.type,
    required this.action,
    this.param,
  });
}

// ── Default grid layout (5×4) ──────────────────────────────────────────────
const defaultButtonLayout = <List<String>>[
  ['clear', 'toggle_sign', 'percent', 'op_divide'],
  ['digit_7', 'digit_8', 'digit_9', 'op_multiply'],
  ['digit_4', 'digit_5', 'digit_6', 'op_subtract'],
  ['digit_1', 'digit_2', 'digit_3', 'op_add'],
  ['paren', 'digit_0', 'decimal', 'equals'],
];

// ── All available buttons ──────────────────────────────────────────────────
const allButtonDefs = <CalcButtonDef>[
  // ── Digits ───────────────────────────────────────────────────────────────
  CalcButtonDef(id: 'digit_0', label: '0', type: CalcButtonType.number, action: ButtonAction.digit, param: '0'),
  CalcButtonDef(id: 'digit_1', label: '1', type: CalcButtonType.number, action: ButtonAction.digit, param: '1'),
  CalcButtonDef(id: 'digit_2', label: '2', type: CalcButtonType.number, action: ButtonAction.digit, param: '2'),
  CalcButtonDef(id: 'digit_3', label: '3', type: CalcButtonType.number, action: ButtonAction.digit, param: '3'),
  CalcButtonDef(id: 'digit_4', label: '4', type: CalcButtonType.number, action: ButtonAction.digit, param: '4'),
  CalcButtonDef(id: 'digit_5', label: '5', type: CalcButtonType.number, action: ButtonAction.digit, param: '5'),
  CalcButtonDef(id: 'digit_6', label: '6', type: CalcButtonType.number, action: ButtonAction.digit, param: '6'),
  CalcButtonDef(id: 'digit_7', label: '7', type: CalcButtonType.number, action: ButtonAction.digit, param: '7'),
  CalcButtonDef(id: 'digit_8', label: '8', type: CalcButtonType.number, action: ButtonAction.digit, param: '8'),
  CalcButtonDef(id: 'digit_9', label: '9', type: CalcButtonType.number, action: ButtonAction.digit, param: '9'),

  // ── Operators ────────────────────────────────────────────────────────────
  CalcButtonDef(id: 'op_add', label: '+', type: CalcButtonType.operator, action: ButtonAction.operator, param: 'add'),
  CalcButtonDef(id: 'op_subtract', label: '−', type: CalcButtonType.operator, action: ButtonAction.operator, param: 'subtract'),
  CalcButtonDef(id: 'op_multiply', label: '×', type: CalcButtonType.operator, action: ButtonAction.operator, param: 'multiply'),
  CalcButtonDef(id: 'op_divide', label: '÷', type: CalcButtonType.operator, action: ButtonAction.operator, param: 'divide'),

  // ── Functions ────────────────────────────────────────────────────────────
  CalcButtonDef(id: 'clear', label: 'AC', type: CalcButtonType.clear, action: ButtonAction.clear),
  CalcButtonDef(id: 'toggle_sign', label: '+/−', type: CalcButtonType.function, action: ButtonAction.function, param: 'toggle_sign'),
  CalcButtonDef(id: 'percent', label: '%', type: CalcButtonType.function, action: ButtonAction.function, param: 'percent'),
  CalcButtonDef(id: 'paren', label: '( )', type: CalcButtonType.function, action: ButtonAction.function, param: 'paren'),
  CalcButtonDef(id: 'decimal', label: '.', type: CalcButtonType.number, action: ButtonAction.digit, param: '.'),
  CalcButtonDef(id: 'equals', label: '=', type: CalcButtonType.equal, action: ButtonAction.calculate),

  // ── Special ──────────────────────────────────────────────────────────────
  CalcButtonDef(id: 'sqrt', label: '√', type: CalcButtonType.function, action: ButtonAction.special, param: 'sqrt'),
  CalcButtonDef(id: 'ai', label: 'AI', type: CalcButtonType.function, action: ButtonAction.special, param: 'ai'),

  // ── Tool shortcuts (navigate to tool screens) ────────────────────────────
  CalcButtonDef(id: 'tool_currency', label: '환율', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/currency'),
  CalcButtonDef(id: 'tool_crypto', label: '코인', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/crypto'),
  CalcButtonDef(id: 'tool_discount', label: '할인', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/discount'),
  CalcButtonDef(id: 'tool_vat', label: '부가세', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/vat'),
  CalcButtonDef(id: 'tool_loan', label: '대출', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/loan'),
  CalcButtonDef(id: 'tool_capital_gains_tax', label: '양도세', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/capital-gains-tax'),
  CalcButtonDef(id: 'tool_brokerage_fee', label: '복비', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/brokerage-fee'),
  CalcButtonDef(id: 'tool_dday', label: 'D-day', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/dday'),
  CalcButtonDef(id: 'tool_birthday', label: '생일', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/birthday'),
  CalcButtonDef(id: 'tool_world_clock', label: '시계', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/world-clock'),
  CalcButtonDef(id: 'tool_unit', label: '단위', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/unit'),
  CalcButtonDef(id: 'tool_bmi', label: 'BMI', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/bmi'),
  CalcButtonDef(id: 'tool_fuel', label: '연비', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/fuel'),
  CalcButtonDef(id: 'tool_period', label: '생리', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/period'),
  CalcButtonDef(id: 'tool_base_converter', label: '진법', type: CalcButtonType.function, action: ButtonAction.navigate, param: '/tools/base-converter'),
];

/// Lookup a button definition by ID.
CalcButtonDef? getButtonDef(String id) {
  for (final def in allButtonDefs) {
    if (def.id == id) return def;
  }
  return null;
}

/// Group buttons by category for the swap modal.
const buttonCategories = <String, List<String>>{
  '숫자': [
    'digit_0', 'digit_1', 'digit_2', 'digit_3', 'digit_4',
    'digit_5', 'digit_6', 'digit_7', 'digit_8', 'digit_9',
  ],
  '연산': [
    'op_add', 'op_subtract', 'op_multiply', 'op_divide',
  ],
  '기능': [
    'clear', 'toggle_sign', 'percent', 'paren', 'decimal', 'equals',
    'sqrt', 'ai',
  ],
  '도구': [
    'tool_currency', 'tool_crypto', 'tool_discount', 'tool_vat',
    'tool_loan', 'tool_capital_gains_tax', 'tool_brokerage_fee',
    'tool_dday', 'tool_birthday', 'tool_world_clock',
    'tool_unit', 'tool_bmi', 'tool_fuel', 'tool_period', 'tool_base_converter',
  ],
};
