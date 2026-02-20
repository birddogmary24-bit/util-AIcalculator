import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    return ToolScaffold(
      title: '양도세 계산기',
      children: [
        // ── 양도가액 ─────────────────────────────────────────────────────
        LabeledInputField(
          label: '양도가액 (매도 금액)',
          hint: '매도 금액을 입력하세요',
          suffix: '원',
          controller: _sellingController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(capitalGainsTaxProvider.notifier).setSellingPrice(parsed);
          },
        ),

        const SizedBox(height: 20),

        // ── 취득가액 ─────────────────────────────────────────────────────
        LabeledInputField(
          label: '취득가액 (매수 금액)',
          hint: '매수 금액을 입력하세요',
          suffix: '원',
          controller: _purchaseController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(capitalGainsTaxProvider.notifier).setPurchasePrice(parsed);
          },
        ),

        const SizedBox(height: 20),

        // ── 필요경비 ─────────────────────────────────────────────────────
        LabeledInputField(
          label: '필요경비 (중개수수료, 법무사비 등)',
          hint: '경비를 입력하세요',
          suffix: '원',
          controller: _expensesController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(capitalGainsTaxProvider.notifier).setExpenses(parsed);
          },
        ),

        const SizedBox(height: 24),

        // ── 주택 수 (SegmentedButton) ────────────────────────────────────
        _buildSectionLabel('주택 수'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<HouseCount>(
            segments: const [
              ButtonSegment<HouseCount>(
                value: HouseCount.one,
                label: Text(
                  '1주택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ButtonSegment<HouseCount>(
                value: HouseCount.two,
                label: Text(
                  '2주택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ButtonSegment<HouseCount>(
                value: HouseCount.threeOrMore,
                label: Text(
                  '3주택+',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          label: '보유 기간',
          value: state.holdingPeriod,
          items: const [
            DropdownMenuItem(
              value: HoldingPeriod.underOneYear,
              child: Text('1년 미만', style: TextStyle(fontSize: 18)),
            ),
            DropdownMenuItem(
              value: HoldingPeriod.oneToTwo,
              child: Text('1년~2년', style: TextStyle(fontSize: 18)),
            ),
            DropdownMenuItem(
              value: HoldingPeriod.overTwo,
              child: Text('2년 이상', style: TextStyle(fontSize: 18)),
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
            label: '보유 연수 (장기보유특별공제 계산용)',
            hint: '예: 5',
            suffix: '년',
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
            label: '비과세 적용 (1주택 9억 이하)',
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
            '계산 결과',
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
          label: '양도차익',
          value: _formatNumber(state.gain),
          unit: '원',
        ),

        const SizedBox(height: 12),

        // ── 장기보유특별공제 ─────────────────────────────────────────────
        if (state.longTermDeduction > 0) ...[
          ResultDisplayCard(
            label: '장기보유특별공제',
            value: '- ${_formatNumber(state.longTermDeduction)}',
            unit: '원',
            accentColor: const Color(0xFF43A047),
          ),
          const SizedBox(height: 12),
        ],

        // ── 기본공제 ─────────────────────────────────────────────────────
        ResultDisplayCard(
          label: '양도소득 기본공제',
          value: '- ${_formatNumber(state.basicDeduction)}',
          unit: '원',
          accentColor: const Color(0xFF43A047),
        ),

        const SizedBox(height: 12),

        // ── 과세표준 ─────────────────────────────────────────────────────
        ResultDisplayCard(
          label: '과세표준',
          value: _formatNumber(state.taxableAmount),
          unit: '원',
        ),

        const SizedBox(height: 12),

        // ── 적용 세율 ────────────────────────────────────────────────────
        _buildInfoRow(
          '적용 세율',
          state.additionalRatePoints > 0
              ? '기본 ${(state.appliedRate - state.additionalRatePoints).toStringAsFixed(0)}% + 중과 ${state.additionalRatePoints.toStringAsFixed(0)}%p'
              : '${state.appliedRate.toStringAsFixed(0)}%',
        ),

        const SizedBox(height: 16),

        // ── 양도소득세 ───────────────────────────────────────────────────
        ResultDisplayCard(
          label: '양도소득세',
          value: _formatNumber(state.incomeTax),
          unit: '원',
          accentColor: cs.error,
        ),

        const SizedBox(height: 12),

        // ── 지방소득세 ───────────────────────────────────────────────────
        ResultDisplayCard(
          label: '지방소득세 (양도소득세의 10%)',
          value: _formatNumber(state.localTax),
          unit: '원',
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
                '총 납부 세액',
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
                    '원',
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
            '※ 본 계산은 참고용이며, 정확한 세금은 세무사에 문의하세요.',
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
