import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/calculator_engine.dart';
import '../../../domain/models/button_definition.dart';
import '../../../providers/button_config_provider.dart';
import '../calculator_provider.dart';
import 'button_swap_modal.dart';
import 'calc_button.dart';

class ButtonGrid extends ConsumerWidget {
  const ButtonGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(calculatorProvider.notifier);
    final calcState = ref.watch(calculatorProvider);
    final layout = ref.watch(buttonConfigProvider);
    final isAllClear =
        calcState.display == '0' && calcState.expression.isEmpty;
    final openParens = calcState.openParens;

    // Collect all currently placed button IDs
    final currentIds = <String>{};
    for (final row in layout) {
      currentIds.addAll(row);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const gap = 6.0;
        final btnSize = (totalWidth - gap * 3) / 4;

        return Column(
          children: [
            // Hint text
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '버튼을 길게 누르면 변경이 가능합니다',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Utility row (고급계산, 설정1~4)
            Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF555555)
                        : const Color(0xFFCCCCCC),
                    width: 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (ctx, innerConstraints) {
                    return _buildUtilityRow(ctx, innerConstraints.maxWidth, gap);
                  },
                ),
              ),
            ),
            // Main button grid
            ...List.generate(layout.length, (rowIdx) {
              final row = layout[rowIdx];
              final buttons = List.generate(row.length, (colIdx) {
                final btnId = row[colIdx];
                return _buildButton(
                  context: context,
                  ref: ref,
                  notifier: notifier,
                  btnId: btnId,
                  btnSize: btnSize,
                  isAllClear: isAllClear,
                  openParens: openParens,
                  rowIdx: rowIdx,
                  colIdx: colIdx,
                  currentIds: currentIds,
                );
              });
              return Padding(
                padding: EdgeInsets.only(bottom: rowIdx < layout.length - 1 ? gap : 0),
                child: _buildRow(btnSize, gap, buttons),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required WidgetRef ref,
    required CalculatorNotifier notifier,
    required String btnId,
    required double btnSize,
    required bool isAllClear,
    required int openParens,
    required int rowIdx,
    required int colIdx,
    required Set<String> currentIds,
  }) {
    final def = getButtonDef(btnId);
    if (def == null) {
      return SizedBox(width: btnSize, height: btnSize * 0.8);
    }

    // Determine dynamic label for special cases
    String label = def.label;
    if (btnId == 'clear') {
      label = isAllClear ? 'AC' : 'C';
    } else if (btnId == 'paren') {
      label = openParens > 0 ? ')' : '( )';
    }

    // Determine tap action
    final onTap = _resolveAction(context, ref, notifier, def);

    // Font size: smaller for tool buttons with longer labels
    final isToolBtn = def.action == ButtonAction.navigate;
    final fontSize = isToolBtn ? btnSize * 0.28 : null;

    return CalcButton(
      label: label,
      type: def.type,
      onTap: onTap,
      fontSize: fontSize,
      onLongPress: () async {
        final selected = await showButtonSwapModal(
          context,
          currentIds: currentIds,
        );
        if (selected == null) return;
        if (isResetResult(selected)) {
          ref.read(buttonConfigProvider.notifier).resetToDefault();
        } else {
          ref
              .read(buttonConfigProvider.notifier)
              .swapButton(rowIdx, colIdx, selected);
        }
      },
    );
  }

  VoidCallback _resolveAction(
    BuildContext context,
    WidgetRef ref,
    CalculatorNotifier notifier,
    CalcButtonDef def,
  ) {
    switch (def.action) {
      case ButtonAction.digit:
        return () => notifier.inputDigit(def.param!);
      case ButtonAction.operator:
        return () {
          final op = _parseOp(def.param!);
          notifier.inputOperator(op);
        };
      case ButtonAction.function:
        switch (def.param) {
          case 'toggle_sign':
            return notifier.toggleSign;
          case 'percent':
            return notifier.percentage;
          case 'paren':
            return notifier.inputParen;
          default:
            return () {};
        }
      case ButtonAction.calculate:
        return notifier.calculate;
      case ButtonAction.clear:
        final calcState = ref.read(calculatorProvider);
        final isAllClear =
            calcState.display == '0' && calcState.expression.isEmpty;
        return isAllClear ? notifier.allClear : notifier.clear;
      case ButtonAction.navigate:
        return () => context.push(def.param!);
      case ButtonAction.special:
        switch (def.param) {
          case 'sqrt':
            return () => notifier.squareRoot();
          case 'ai':
            // Focus on the natural language input bar
            return () {
              FocusScope.of(context).nextFocus();
            };
          default:
            return () {};
        }
    }
  }

  CalcOp _parseOp(String param) {
    switch (param) {
      case 'add':
        return CalcOp.add;
      case 'subtract':
        return CalcOp.subtract;
      case 'multiply':
        return CalcOp.multiply;
      case 'divide':
        return CalcOp.divide;
      default:
        return CalcOp.none;
    }
  }

  Widget _buildRow(double btnSize, double gap, List<Widget> buttons) {
    return Row(
      children: buttons
          .map((btn) =>
              SizedBox(width: btnSize, height: btnSize * 0.8, child: btn))
          .expand((w) => [w, SizedBox(width: gap)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildUtilityRow(BuildContext context, double totalWidth, double gap) {
    const labels = ['고급계산', '설정1', '설정2', '설정3', '설정4'];
    final btnWidth = (totalWidth - gap * (labels.length - 1)) / labels.length;
    const btnHeight = 34.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final buttons = labels.map((label) {
      return SizedBox(
        width: btnWidth,
        height: btnHeight,
        child: GestureDetector(
          onTap: () {
            // placeholder — will be connected later
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3A3D45) : const Color(0xFFE8E8EC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Row(
      children: buttons
          .expand((w) => [w, SizedBox(width: gap)])
          .toList()
        ..removeLast(),
    );
  }
}
