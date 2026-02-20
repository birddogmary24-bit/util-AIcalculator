import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import '../../common/widgets/styled_dropdown.dart';
import 'base_converter_provider.dart';

class BaseConverterScreen extends ConsumerStatefulWidget {
  const BaseConverterScreen({super.key});

  @override
  ConsumerState<BaseConverterScreen> createState() =>
      _BaseConverterScreenState();
}

class _BaseConverterScreenState extends ConsumerState<BaseConverterScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _baseLabel(int base) {
    switch (base) {
      case 2:
        return '2진수 (Binary)';
      case 8:
        return '8진수 (Octal)';
      case 10:
        return '10진수 (Decimal)';
      case 16:
        return '16진수 (Hex)';
      default:
        return '$base진수';
    }
  }

  String _hintForBase(int base) {
    switch (base) {
      case 2:
        return '0과 1만 입력 (예: 1010)';
      case 8:
        return '0~7만 입력 (예: 377)';
      case 10:
        return '0~9만 입력 (예: 255)';
      case 16:
        return '0~9, A~F 입력 (예: FF)';
      default:
        return '값을 입력하세요';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(baseConverterProvider);

    return ToolScaffold(
      title: '진수 계산기',
      children: [
        // 입력 진수 선택
        StyledDropdown<int>(
          label: '입력 진수 선택',
          value: state.fromBase,
          items: [2, 8, 10, 16]
              .map(
                (b) => DropdownMenuItem<int>(
                  value: b,
                  child: Text(
                    _baseLabel(b),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              ref.read(baseConverterProvider.notifier).setFromBase(v);
            }
          },
        ),

        const SizedBox(height: 20),

        // 값 입력
        LabeledInputField(
          label: '변환할 값',
          hint: _hintForBase(state.fromBase),
          controller: _inputController,
          keyboardType: TextInputType.text,
          onChanged: (v) {
            ref.read(baseConverterProvider.notifier).setInput(v);
          },
        ),

        // 유효하지 않은 입력 경고
        if (!state.isValid && state.input.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_baseLabel(state.fromBase)}에 유효하지 않은 값입니다',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: cs.error,
              ),
            ),
          ),

        const SizedBox(height: 24),

        // 결과 표시 — 4개의 진수
        ResultDisplayCard(
          label: '2진수 (Binary)',
          value: state.binary,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: '8진수 (Octal)',
          value: state.octal,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: '10진수 (Decimal)',
          value: state.decimal,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: '16진수 (Hex)',
          value: state.hex,
        ),
      ],
    );
  }
}
