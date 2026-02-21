import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 정수 입력 필드에 실시간으로 천 단위 쉼표를 삽입하는 InputFormatter.
///
/// 사용법:
/// ```dart
/// inputFormatters: [ThousandsSeparatorInputFormatter()],
/// onChanged: (v) {
///   final plain = v.replaceAll(',', '');
///   // plain을 파싱해서 사용
/// },
/// ```
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final _fmt = NumberFormat('#,##0');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');

    // 빈 문자열이면 그대로
    if (raw.isEmpty) return newValue.copyWith(text: '');

    // 숫자만 허용
    if (int.tryParse(raw) == null) return oldValue;

    final formatted = _fmt.format(int.parse(raw));

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
