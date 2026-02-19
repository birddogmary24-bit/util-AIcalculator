import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/calculator_engine.dart';
import '../calculator_provider.dart';
import 'calc_button.dart';

class ButtonGrid extends ConsumerWidget {
  const ButtonGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(calculatorProvider.notifier);
    final isAllClear = ref.watch(calculatorProvider).display == '0' &&
        ref.watch(calculatorProvider).expression.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // 4 columns with gaps
        const gap = 12.0;
        final btnSize = (totalWidth - gap * 3) / 4;

        return Column(
          children: [
            // Row 1: AC/C, +/-, %, ÷
            _buildRow(btnSize, gap, [
              CalcButton(
                label: isAllClear ? 'AC' : 'C',
                type: CalcButtonType.function,
                onTap: isAllClear
                    ? notifier.allClear
                    : notifier.clear,
              ),
              CalcButton(
                label: '+/-',
                type: CalcButtonType.function,
                onTap: notifier.toggleSign,
              ),
              CalcButton(
                label: '%',
                type: CalcButtonType.function,
                onTap: notifier.percentage,
              ),
              CalcButton(
                label: '÷',
                type: CalcButtonType.operator,
                onTap: () => notifier.inputOperator(CalcOp.divide),
              ),
            ]),
            SizedBox(height: gap),

            // Row 2: 7, 8, 9, ×
            _buildRow(btnSize, gap, [
              CalcButton(
                label: '7',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('7'),
              ),
              CalcButton(
                label: '8',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('8'),
              ),
              CalcButton(
                label: '9',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('9'),
              ),
              CalcButton(
                label: '×',
                type: CalcButtonType.operator,
                onTap: () => notifier.inputOperator(CalcOp.multiply),
              ),
            ]),
            SizedBox(height: gap),

            // Row 3: 4, 5, 6, -
            _buildRow(btnSize, gap, [
              CalcButton(
                label: '4',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('4'),
              ),
              CalcButton(
                label: '5',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('5'),
              ),
              CalcButton(
                label: '6',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('6'),
              ),
              CalcButton(
                label: '−',
                type: CalcButtonType.operator,
                onTap: () => notifier.inputOperator(CalcOp.subtract),
              ),
            ]),
            SizedBox(height: gap),

            // Row 4: 1, 2, 3, +
            _buildRow(btnSize, gap, [
              CalcButton(
                label: '1',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('1'),
              ),
              CalcButton(
                label: '2',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('2'),
              ),
              CalcButton(
                label: '3',
                type: CalcButtonType.number,
                onTap: () => notifier.inputDigit('3'),
              ),
              CalcButton(
                label: '+',
                type: CalcButtonType.operator,
                onTap: () => notifier.inputOperator(CalcOp.add),
              ),
            ]),
            SizedBox(height: gap),

            // Row 5: 0 (double-wide), ., =
            Row(
              children: [
                // 0 button: 2 columns wide
                SizedBox(
                  width: btnSize * 2 + gap,
                  height: btnSize,
                  child: CalcButton(
                    label: '0',
                    type: CalcButtonType.zero,
                    onTap: () => notifier.inputDigit('0'),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: btnSize,
                  height: btnSize,
                  child: CalcButton(
                    label: '.',
                    type: CalcButtonType.number,
                    onTap: () => notifier.inputDigit('.'),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: btnSize,
                  height: btnSize,
                  child: CalcButton(
                    label: '=',
                    type: CalcButtonType.equal,
                    onTap: notifier.calculate,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(double btnSize, double gap, List<Widget> buttons) {
    return Row(
      children: buttons
          .map((btn) => SizedBox(width: btnSize, height: btnSize, child: btn))
          .expand((w) => [w, SizedBox(width: gap)])
          .toList()
        ..removeLast(),
    );
  }
}
