import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/thousands_input_formatter.dart';

import '../../../core/constants/region.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import '../../common/widgets/styled_dropdown.dart';
import 'capital_gains_tax_provider.dart';

final _fmt = NumberFormat('#,##0');
String _formatNumber(double v) => _fmt.format(v);

class CapitalGainsTaxScreen extends ConsumerStatefulWidget {
  const CapitalGainsTaxScreen({super.key});

  @override
  ConsumerState<CapitalGainsTaxScreen> createState() =>
      _CapitalGainsTaxScreenState();
}

class _CapitalGainsTaxScreenState
    extends ConsumerState<CapitalGainsTaxScreen> {
  final _sellingController = TextEditingController();
  final _purchaseController = TextEditingController();
  final _expensesController = TextEditingController();
  final _holdingYearsController = TextEditingController(text: '3');

  @override
  void dispose() {
    _sellingController.dispose();
    _purchaseController.dispose();
    _expensesController.dispose();
    _holdingYearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(capitalGainsTaxProvider);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : 'KRW';

    return ToolScaffold(
      title: isKr ? '양도세 계산기' : 'Capital Gains Tax',
      children: [
        // ── 양도가액 ─────────────────────────────────────────────────────
        LabeledInputField(
          label: isKr ? '양도가액 (매도 금액)' : 'Sale Price',
          hint: isKr ? '매도 금액을 입력하세요' : 'Enter sale price',
          suffix: currencyUnit,
          controller: _sellingController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(capitalGainsTaxProvider.notifier).setSellingPrice(parsed);
          },
        ),

        const SizedBox(height: 20),

        // ── 취득가액 ─────────────────────────────────────────────────────
        LabeledInputField(
          label: isKr ? '취득가액 (매수 금액)' : 'Purchase Price',
          hint: isKr ? '매수 금액을 입력하세요' : 'Enter purchase price',
          suffix: currencyUnit,
          controller: _purchaseController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(capitalGainsTaxProvider.notifier).setPurchasePrice(parsed);
          },
        ),

        const SizedBox(height: 20),

        // ── 필요경비 ─────────────────────────────────────────────────────
        LabeledInputField(
          label: isKr
              ? '필요경비 (중개수수료, 법무사비 등)'
              : 'Expenses (brokerage, legal fees, etc.)',
          hint: isKr ? '경비를 입력하세요' : 'Enter expenses',
          suffix: currencyUnit,
          controller: _expensesController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(capitalGainsTaxProvider.notifier).setExpenses(parsed);
          },
        ),

        const SizedBox(height: 24),

        // ── 주택 수 (SegmentedButton) ────────────────────────────────────
        _buildSectionLabel(isKr ? '주택 수' : 'Number of Houses'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<HouseCount>(
            segments: [
              ButtonSegment<HouseCount>(
                value: HouseCount.one,
                label: Text(
                  isKr ? '1주택' : '1 House',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ButtonSegment<HouseCount>(
                value: HouseCount.two,
                label: Text(
                  isKr ? '2주택' : '2 Houses',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ButtonSegment<HouseCount>(
                value: HouseCount.threeOrMore,
                label: Text(
                  isKr ? '3주택+' : '3+',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            selected: {state.houseCount},
            onSelectionChanged: (selected) {
              ref
                  .read(capitalGainsTaxProvider.notifier)
                  .setHouseCount(selected.first);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: cs.surfaceContainerLow,
              selectedBackgroundColor: cs.primary,
              selectedForegroundColor: cs.onPrimary,
              foregroundColor: cs.onSurface,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── 보유 기간 ────────────────────────────────────────────────────
        StyledDropdown<HoldingPeriod>(
          label: isKr ? '보유 기간' : 'Holding Period',
          value: state.holdingPeriod,
          items: [
            DropdownMenuItem(
              value: HoldingPeriod.underOneYear,
              child: Text(isKr ? '1년 미만' : 'Under 1 year',
                  style: const TextStyle(fontSize: 18)),
            ),
            DropdownMenuItem(
              value: HoldingPeriod.oneToTwo,
              child: Text(isKr ? '1년~2년' : '1-2 years',
                  style: const TextStyle(fontSize: 18)),
            ),
            DropdownMenuItem(
              value: HoldingPeriod.overTwo,
              child: Text(isKr ? '2년 이상' : '2+ years',
                  style: const TextStyle(fontSize: 18)),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              ref.read(capitalGainsTaxProvider.notifier).setHoldingPeriod(v);
            }
          },
        ),

        // ── 보유 연수 (2년 이상일 때만 표시) ─────────────────────────────
        if (state.holdingPeriod == HoldingPeriod.overTwo) ...[
          const SizedBox(height: 20),
          LabeledInputField(
            label: isKr
                ? '보유 연수 (장기보유특별공제 계산용)'
                : 'Holding Years (for long-term deduction)',
            hint: isKr ? '예: 5' : 'e.g. 5',
            suffix: isKr ? '년' : 'yrs',
            controller: _holdingYearsController,
            onChanged: (v) {
              final parsed = int.tryParse(v) ?? 0;
              ref
                  .read(capitalGainsTaxProvider.notifier)
                  .setHoldingYears(parsed);
            },
          ),
        ],

        const SizedBox(height: 20),

        // ── 비과세 적용 여부 ─────────────────────────────────────────────
        if (state.houseCount == HouseCount.one)
          _buildCheckboxRow(
            label: isKr
                ? '비과세 적용 (1주택 9억 이하)'
                : 'Tax Exempt (1 house, under 900M)',
            value: state.taxExempt,
            onChanged: (v) {
              ref
                  .read(capitalGainsTaxProvider.notifier)
                  .setTaxExempt(v ?? false);
            },
          ),

        const SizedBox(height: 28),

        // ── 계산 결과 제목 ───────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant, width: 2),
            ),
          ),
          child: Text(
            isKr ? '계산 결과' : 'Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 양도차익 ─────────────────────────────────────────────────────
        ResultDisplayCard(
          label: isKr ? '양도차익' : 'Capital Gain',
          value: _formatNumber(state.gain),
          unit: currencyUnit,
        ),

        const SizedBox(height: 12),

        // ── 장기보유특별공제 ─────────────────────────────────────────────
        if (state.longTermDeduction > 0) ...[
          ResultDisplayCard(
            label: isKr ? '장기보유특별공제' : 'Long-term Holding Deduction',
            value: '- ${_formatNumber(state.longTermDeduction)}',
            unit: currencyUnit,
            accentColor: const Color(0xFF43A047),
          ),
          const SizedBox(height: 12),
        ],

        // ── 기본공제 ─────────────────────────────────────────────────────
        ResultDisplayCard(
          label: isKr ? '양도소득 기본공제' : 'Basic Deduction',
          value: '- ${_formatNumber(state.basicDeduction)}',
          unit: currencyUnit,
          accentColor: const Color(0xFF43A047),
        ),

        const SizedBox(height: 12),

        // ── 과세표준 ─────────────────────────────────────────────────────
        ResultDisplayCard(
          label: isKr ? '과세표준' : 'Taxable Amount',
          value: _formatNumber(state.taxableAmount),
          unit: currencyUnit,
        ),

        const SizedBox(height: 12),

        // ── 적용 세율 ────────────────────────────────────────────────────
        _buildInfoRow(
          isKr ? '적용 세율' : 'Tax Rate',
          state.additionalRatePoints > 0
              ? isKr
                  ? '기본 ${(state.appliedRate - state.additionalRatePoints).toStringAsFixed(0)}% + 중과 ${state.additionalRatePoints.toStringAsFixed(0)}%p'
                  : 'Base ${(state.appliedRate - state.additionalRatePoints).toStringAsFixed(0)}% + Surcharge ${state.additionalRatePoints.toStringAsFixed(0)}%p'
              : '${state.appliedRate.toStringAsFixed(0)}%',
        ),

        const SizedBox(height: 16),

        // ── 양도소득세 ───────────────────────────────────────────────────
        ResultDisplayCard(
          label: isKr ? '양도소득세' : 'Capital Gains Tax',
          value: _formatNumber(state.incomeTax),
          unit: currencyUnit,
          accentColor: cs.error,
        ),

        const SizedBox(height: 12),

        // ── 지방소득세 ───────────────────────────────────────────────────
        ResultDisplayCard(
          label: isKr ? '지방소득세 (양도소득세의 10%)' : 'Local Tax (10% of CGT)',
          value: _formatNumber(state.localTax),
          unit: currencyUnit,
          accentColor: cs.error,
        ),

        const SizedBox(height: 16),

        // ── 총 납부 세액 ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKr ? '총 납부 세액' : 'Total Tax Due',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onErrorContainer,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      _formatNumber(state.totalTax),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: cs.onErrorContainer,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currencyUnit,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: cs.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── 면책 조항 ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isKr
                ? '※ 본 계산은 참고용이며, 정확한 세금은 세무사에 문의하세요.'
                : '※ This calculation is for reference only. Consult a tax professional for accurate figures.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Helper builders ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
