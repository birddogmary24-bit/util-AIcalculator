import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import 'brokerage_fee_provider.dart';

class BrokerageFeeScreen extends ConsumerStatefulWidget {
  const BrokerageFeeScreen({super.key});

  @override
  ConsumerState<BrokerageFeeScreen> createState() =>
      _BrokerageFeeScreenState();
}

class _BrokerageFeeScreenState extends ConsumerState<BrokerageFeeScreen> {
  final _saleAmountCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _monthlyRentCtrl = TextEditingController();
  final _currencyFmt = NumberFormat('#,##0');

  @override
  void dispose() {
    _saleAmountCtrl.dispose();
    _depositCtrl.dispose();
    _monthlyRentCtrl.dispose();
    super.dispose();
  }

  String _formatWon(double amount) {
    if (amount >= 100000000) {
      final eok = amount / 100000000;
      final remainder = (amount % 100000000) / 10000;
      if (remainder > 0) {
        return '${_currencyFmt.format(eok)}억 ${_currencyFmt.format(remainder)}만원';
      }
      return '${_currencyFmt.format(eok)}억원';
    } else if (amount >= 10000) {
      return '${_currencyFmt.format(amount / 10000)}만원';
    }
    return '${_currencyFmt.format(amount)}원';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(brokerageFeeProvider);
    final notifier = ref.read(brokerageFeeProvider.notifier);

    return ToolScaffold(
      title: '복비 계산기',
      children: [
        // ── Transaction Type ────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '거래 유형',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.sale,
                    label: Text('매매', style: TextStyle(fontSize: 18)),
                    icon: Icon(Icons.home),
                  ),
                  ButtonSegment(
                    value: TransactionType.lease,
                    label: Text('임대(전월세)', style: TextStyle(fontSize: 18)),
                    icon: Icon(Icons.apartment),
                  ),
                ],
                selected: {state.type},
                onSelectionChanged: (selected) {
                  notifier.setType(selected.first);
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

        // ── Inputs ──────────────────────────────────────
        if (state.type == TransactionType.sale) ...[
          LabeledInputField(
            label: '거래 금액 (원)',
            hint: '예: 350000000',
            suffix: '원',
            controller: _saleAmountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) =>
                notifier.setSaleAmount(double.tryParse(v) ?? 0),
          ),
        ] else ...[
          LabeledInputField(
            label: '보증금 (원)',
            hint: '예: 50000000',
            suffix: '원',
            controller: _depositCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) =>
                notifier.setDeposit(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 16),
          LabeledInputField(
            label: '월세 (원)',
            hint: '예: 500000',
            suffix: '원',
            controller: _monthlyRentCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) =>
                notifier.setMonthlyRent(double.tryParse(v) ?? 0),
          ),
          if (state.deposit > 0 || state.monthlyRent > 0) ...[
            const SizedBox(height: 8),
            Text(
              '환산 금액: ${_formatWon(state.deposit + (state.monthlyRent * 100))}',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
        const SizedBox(height: 28),

        // ── Results ─────────────────────────────────────
        if (state.fee > 0) ...[
          ResultDisplayCard(
            label: '적용 요율',
            value: '${state.rate}%',
            accentColor: cs.primary,
          ),
          const SizedBox(height: 12),

          ResultDisplayCard(
            label: '중개수수료',
            value: _currencyFmt.format(state.fee),
            unit: '원',
          ),
          const SizedBox(height: 12),

          if (state.hasCap)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '상한액 ${_formatWon(state.cap ?? 0)} 적용됨',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],

        // ── Rate Table Reference ────────────────────────
        _buildRateTable(state.type, cs),
      ],
    );
  }

  Widget _buildRateTable(TransactionType type, ColorScheme cs) {
    final isSale = type == TransactionType.sale;
    final title = isSale ? '매매/교환 요율표 (2024 기준)' : '임대차 요율표 (2024 기준)';

    final rows = isSale
        ? [
            ['5천만 미만', '0.6%', '25만원'],
            ['5천만~2억 미만', '0.5%', '80만원'],
            ['2억~9억 미만', '0.4%', '-'],
            ['9억~12억 미만', '0.5%', '-'],
            ['12억~15억 미만', '0.6%', '-'],
            ['15억 이상', '0.7%', '-'],
          ]
        : [
            ['5천만 미만', '0.5%', '20만원'],
            ['5천만~1억 미만', '0.4%', '30만원'],
            ['1억~6억 미만', '0.3%', '-'],
            ['6억~12억 미만', '0.4%', '-'],
            ['12억~15억 미만', '0.5%', '-'],
            ['15억 이상', '0.6%', '-'],
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('거래금액',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('요율',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('상한액',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant),
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
              for (final row in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(row[0],
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurface)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(row[1],
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurface),
                          textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(row[2],
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurface),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
