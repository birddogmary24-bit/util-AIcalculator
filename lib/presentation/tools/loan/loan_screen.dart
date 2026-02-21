import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../core/utils/thousands_input_formatter.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import 'loan_provider.dart';

class LoanScreen extends ConsumerStatefulWidget {
  const LoanScreen({super.key});

  @override
  ConsumerState<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends ConsumerState<LoanScreen> {
  final _principalCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _currencyFmt = NumberFormat('#,##0');
  bool _showSchedule = false;

  static const _presetMonths = [12, 24, 36, 60, 120, 240, 360];

  @override
  void dispose() {
    _principalCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  String _monthsLabel(int months, bool isKr) {
    if (months >= 12 && months % 12 == 0) {
      final years = months ~/ 12;
      return isKr ? '$years년' : '${years}yr';
    }
    return isKr ? '$months개월' : '${months}mo';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(loanProvider);
    final notifier = ref.read(loanProvider.notifier);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : '\$';

    return ToolScaffold(
      title: isKr ? '대출 이자 계산기' : 'Loan Calculator',
      children: [
        // -- Principal --
        LabeledInputField(
          label: isKr ? '대출 원금 (원)' : 'Loan Principal',
          hint: isKr ? '예: 100000000' : 'e.g. 100000',
          suffix: currencyUnit,
          controller: _principalCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) =>
              notifier.setPrincipal(double.tryParse(v.replaceAll(',', '')) ?? 0),
        ),
        const SizedBox(height: 16),

        // -- Annual Rate --
        LabeledInputField(
          label: isKr ? '연이율 (%)' : 'Annual Rate (%)',
          hint: isKr ? '예: 3.5' : 'e.g. 3.5',
          suffix: '%',
          controller: _rateCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          onChanged: (v) =>
              notifier.setAnnualRate(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 20),

        // -- Period (months) --
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '대출 기간' : 'Loan Period',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetMonths.map((m) {
                final isSelected = state.periodMonths == m;
                return ChoiceChip(
                  label: Text(
                    _monthsLabel(m, isKr),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => notifier.setPeriodMonths(m),
                  selectedColor: cs.primary,
                  backgroundColor: cs.surfaceContainerLow,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // -- Repayment Type --
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '상환 방식' : 'Repayment Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<RepaymentType>(
                segments: [
                  ButtonSegment(
                    value: RepaymentType.equalPrincipalInterest,
                    label: Text(
                      isKr ? '원리금균등' : 'Equal Payment',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  ButtonSegment(
                    value: RepaymentType.equalPrincipal,
                    label: Text(
                      isKr ? '원금균등' : 'Equal Principal',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
                selected: {state.repaymentType},
                onSelectionChanged: (selected) {
                  notifier.setRepaymentType(selected.first);
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
        const SizedBox(height: 28),

        // -- Results --
        if (state.monthlyPayment > 0) ...[
          ResultDisplayCard(
            label: state.repaymentType == RepaymentType.equalPrincipal
                ? (isKr ? '월 납입금 (첫 달)' : 'Monthly Payment (1st)')
                : (isKr ? '월 납입금' : 'Monthly Payment'),
            value: _currencyFmt.format(state.monthlyPayment),
            unit: currencyUnit,
          ),
          const SizedBox(height: 12),

          // For equal principal, show last month payment too
          if (state.repaymentType == RepaymentType.equalPrincipal) ...[
            ResultDisplayCard(
              label: isKr ? '월 납입금 (마지막 달)' : 'Monthly Payment (Last)',
              value: _currencyFmt.format(state.lastMonthPayment),
              unit: currencyUnit,
            ),
            const SizedBox(height: 12),
          ],

          ResultDisplayCard(
            label: isKr ? '총 이자' : 'Total Interest',
            value: _currencyFmt.format(state.totalInterest),
            unit: currencyUnit,
            accentColor: Colors.deepOrange,
          ),
          const SizedBox(height: 12),

          ResultDisplayCard(
            label: isKr ? '총 상환금액' : 'Total Repayment',
            value: _currencyFmt.format(state.totalRepayment),
            unit: currencyUnit,
            accentColor: cs.primary,
          ),
          const SizedBox(height: 20),

          // -- Schedule Toggle --
          if (state.schedule.isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _showSchedule = !_showSchedule),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: cs.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isKr ? '상환 스케줄 보기' : 'View Repayment Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      _showSchedule
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // -- Schedule Table --
            if (_showSchedule) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        SizedBox(
                            width: 36,
                            child: Text(isKr ? '회차' : '#',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant),
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(isKr ? '납입금' : 'Payment',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant),
                                textAlign: TextAlign.right)),
                        Expanded(
                            child: Text(isKr ? '원금' : 'Principal',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant),
                                textAlign: TextAlign.right)),
                        Expanded(
                            child: Text(isKr ? '이자' : 'Interest',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant),
                                textAlign: TextAlign.right)),
                        Expanded(
                            child: Text(isKr ? '잔액' : 'Balance',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant),
                                textAlign: TextAlign.right)),
                      ],
                    ),
                    Divider(color: cs.outlineVariant),
                    // Rows
                    for (final entry in state.schedule) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${entry.month}',
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurface),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _currencyFmt.format(entry.payment),
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurface),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _currencyFmt.format(entry.principalPortion),
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurface),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _currencyFmt.format(entry.interestPortion),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.deepOrange),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _currencyFmt.format(entry.remainingBalance),
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (state.schedule.length < state.periodMonths) ...[
                      Divider(color: cs.outlineVariant),
                      Text(
                        isKr
                            ? '... 외 ${state.periodMonths - state.schedule.length}개월'
                            : '... and ${state.periodMonths - state.schedule.length} more months',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }
}
