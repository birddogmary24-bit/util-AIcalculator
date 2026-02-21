import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../core/utils/thousands_input_formatter.dart';
import '../../../providers/region_provider.dart';
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
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : '\$';

    return ToolScaffold(
      title: isKr ? '부가세 계산기' : 'VAT Calculator',
      children: [
        // VAT inclusive/exclusive toggle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '입력 금액 기준' : 'Input Basis',
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
                segments: [
                  ButtonSegment<VatMode>(
                    value: VatMode.exclusive,
                    label: Text(
                      isKr ? '부가세 미포함' : 'VAT Excluded',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ButtonSegment<VatMode>(
                    value: VatMode.inclusive,
                    label: Text(
                      isKr ? '부가세 포함' : 'VAT Included',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

        // Amount input
        LabeledInputField(
          label: state.mode == VatMode.inclusive
              ? (isKr ? '금액 (부가세 포함)' : 'Amount (VAT Included)')
              : (isKr ? '금액 (부가세 미포함)' : 'Amount (VAT Excluded)'),
          hint: isKr ? '금액을 입력하세요' : 'Enter amount',
          suffix: currencyUnit,
          controller: _amountController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(vatProvider.notifier).setAmount(parsed);
          },
        ),

        const SizedBox(height: 24),

        // Results
        ResultDisplayCard(
          label: isKr ? '공급가액' : 'Supply Price',
          value: _formatNumber(state.supplyAmount),
          unit: currencyUnit,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: isKr ? '부가세액 (10%)' : 'VAT (10%)',
          value: _formatNumber(state.vatAmount),
          unit: currencyUnit,
          accentColor: cs.error,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: isKr ? '합계' : 'Total',
          value: _formatNumber(state.totalAmount),
          unit: currencyUnit,
          accentColor: cs.primary,
        ),
      ],
    );
  }
}
