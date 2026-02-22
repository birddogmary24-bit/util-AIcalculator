import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../core/utils/thousands_input_formatter.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import 'split_bill_provider.dart';

final _fmt = NumberFormat('#,##0.##');
String _formatNumber(double v) => _fmt.format(v);

class SplitBillScreen extends ConsumerStatefulWidget {
  const SplitBillScreen({super.key});

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> {
  final _totalController = TextEditingController();
  bool _showAdjustments = false;

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(splitBillProvider);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : '\$';

    return ToolScaffold(
      title: isKr ? '더치페이' : 'Split Bill',
      children: [
        // Total amount input
        LabeledInputField(
          label: isKr ? '총 금액' : 'Total Amount',
          hint: isKr ? '총 금액을 입력하세요' : 'Enter total bill amount',
          suffix: currencyUnit,
          controller: _totalController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(splitBillProvider.notifier).setTotalAmount(parsed);
          },
        ),

        const SizedBox(height: 20),

        // People count
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '인원수' : 'Number of People',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundButton(
                    icon: Icons.remove,
                    onPressed: state.peopleCount > 1
                        ? () => ref
                            .read(splitBillProvider.notifier)
                            .decrementPeople()
                        : null,
                    color: cs.primary,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      '${state.peopleCount}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  _RoundButton(
                    icon: Icons.add,
                    onPressed: () => ref
                        .read(splitBillProvider.notifier)
                        .incrementPeople(),
                    color: cs.primary,
                  ),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  isKr
                      ? '${state.peopleCount}명'
                      : '${state.peopleCount} ${state.peopleCount == 1 ? 'person' : 'people'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Equal split result
        ResultDisplayCard(
          label: isKr ? '1인당 (균등)' : 'Per Person (Equal Split)',
          value: _formatNumber(state.basePerPerson),
          unit: currencyUnit,
          accentColor: cs.primary,
        ),

        const SizedBox(height: 20),

        // Expandable per-person adjustments section
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() {
                  _showAdjustments = !_showAdjustments;
                }),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isKr ? '개인별 조정' : 'Per-Person Adjustments',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (state.adjustments.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${state.adjustments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _showAdjustments ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showAdjustments) ...[
                Divider(height: 1, color: cs.outlineVariant.withAlpha(60)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      // Description text
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          isKr
                              ? '각 사람의 금액을 조정하세요. 차액은 나머지 인원에게 균등 분배됩니다.'
                              : 'Add or subtract from each person\'s share. '
                                  'Differences are redistributed equally among others.',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant.withAlpha(180),
                          ),
                        ),
                      ),
                      // Person rows
                      ...List.generate(state.peopleCount, (i) {
                        final adj = state.adjustments[i] ?? 0.0;
                        final adjustedAmount = i < state.adjustedAmounts.length
                            ? state.adjustedAmounts[i]
                            : state.basePerPerson;
                        return _PersonAdjustmentRow(
                          index: i,
                          adjustment: adj,
                          finalAmount: adjustedAmount,
                          currencyUnit: currencyUnit,
                          isKr: isKr,
                          onChanged: (val) {
                            ref
                                .read(splitBillProvider.notifier)
                                .setAdjustment(i, val);
                          },
                        );
                      }),
                      if (state.adjustments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: () => ref
                                .read(splitBillProvider.notifier)
                                .clearAdjustments(),
                            icon: Icon(Icons.clear_all,
                                size: 18, color: cs.error),
                            label: Text(
                              isKr ? '조정 초기화' : 'Clear All Adjustments',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.error,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Show adjusted per-person results if there are adjustments
        if (state.adjustments.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            isKr ? '조정된 금액' : 'Adjusted Amounts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(state.peopleCount, (i) {
            final amount = i < state.adjustedAmounts.length
                ? state.adjustedAmounts[i]
                : state.basePerPerson;
            final hasAdj = state.adjustments.containsKey(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ResultDisplayCard(
                label: isKr
                    ? '${i + 1}번${hasAdj ? ' (조정됨)' : ''}'
                    : 'Person ${i + 1}${hasAdj ? ' (adjusted)' : ''}',
                value: _formatNumber(amount),
                unit: currencyUnit,
                accentColor: hasAdj ? cs.tertiary : cs.secondary,
              ),
            );
          }),
        ],
      ],
    );
  }
}

/// A small circular icon button used for increment / decrement controls.
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _RoundButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Material(
      color: isDisabled ? color.withAlpha(30) : color.withAlpha(50),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 24,
            color: isDisabled ? color.withAlpha(80) : color,
          ),
        ),
      ),
    );
  }
}

/// Row for adjusting a single person's share.
class _PersonAdjustmentRow extends StatefulWidget {
  final int index;
  final double adjustment;
  final double finalAmount;
  final String currencyUnit;
  final bool isKr;
  final ValueChanged<double> onChanged;

  const _PersonAdjustmentRow({
    required this.index,
    required this.adjustment,
    required this.finalAmount,
    required this.currencyUnit,
    required this.isKr,
    required this.onChanged,
  });

  @override
  State<_PersonAdjustmentRow> createState() => _PersonAdjustmentRowState();
}

class _PersonAdjustmentRowState extends State<_PersonAdjustmentRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.adjustment != 0
          ? widget.adjustment.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant _PersonAdjustmentRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adjustment != widget.adjustment &&
        widget.adjustment == 0 &&
        _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              widget.isKr ? '${widget.index + 1}번' : 'Person ${widget.index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(signed: true, decimal: true),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.isKr ? '+/- 조정액' : '+/- adjustment',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant.withAlpha(100),
                ),
                prefixText: '${widget.currencyUnit} ',
                prefixStyle: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v) ?? 0;
                widget.onChanged(parsed);
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              '${widget.currencyUnit}${_formatNumber(widget.finalAmount)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.adjustment != 0 ? cs.tertiary : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
