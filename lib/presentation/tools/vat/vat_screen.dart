import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import 'vat_provider.dart';

final _fmt = NumberFormat('#,##0.##');
String _formatNumber(double v) => _fmt.format(v);

class VatScreen extends ConsumerStatefulWidget {
  const VatScreen({super.key});

  @override
  ConsumerState<VatScreen> createState() => _VatScreenState();
}

class _VatScreenState extends ConsumerState<VatScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(vatProvider);

    return ToolScaffold(
      title: '부가세 계산기',
      children: [
        // 부가세 포함/미포함 토글
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '입력 금액 기준',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<VatMode>(
                segments: const [
                  ButtonSegment<VatMode>(
                    value: VatMode.exclusive,
                    label: Text(
                      '부가세 미포함',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ButtonSegment<VatMode>(
                    value: VatMode.inclusive,
                    label: Text(
                      '부가세 포함',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                selected: {state.mode},
                onSelectionChanged: (selected) {
                  ref.read(vatProvider.notifier).setMode(selected.first);
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: cs.surfaceContainerLow,
                  selectedBackgroundColor: cs.primary,
                  selectedForegroundColor: cs.onPrimary,
                  foregroundColor: cs.onSurface,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 금액 입력
        LabeledInputField(
          label: state.mode == VatMode.inclusive ? '금액 (부가세 포함)' : '금액 (부가세 미포함)',
          hint: '금액을 입력하세요',
          suffix: '원',
          controller: _amountController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(vatProvider.notifier).setAmount(parsed);
          },
        ),

        const SizedBox(height: 24),

        // 결과 표시
        ResultDisplayCard(
          label: '공급가액',
          value: _formatNumber(state.supplyAmount),
          unit: '원',
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: '부가세액 (10%)',
          value: _formatNumber(state.vatAmount),
          unit: '원',
          accentColor: cs.error,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: '합계',
          value: _formatNumber(state.totalAmount),
          unit: '원',
          accentColor: cs.primary,
        ),
      ],
    );
  }
}
