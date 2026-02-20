import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import '../../common/widgets/styled_dropdown.dart';
import 'currency_provider.dart';

final _fmt = NumberFormat('#,##0.##');
final _rateFmt = NumberFormat('#,##0.####');

class CurrencyScreen extends ConsumerStatefulWidget {
  const CurrencyScreen({super.key});

  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fetch rates on screen open
    Future.microtask(() {
      ref.read(currencyProvider.notifier).fetchRates();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(currencyProvider);

    return ToolScaffold(
      title: '환율 계산기',
      children: [
        // --- Amount Input ---
        LabeledInputField(
          label: '금액',
          hint: '금액을 입력하세요',
          controller: _amountController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(currencyProvider.notifier).setAmount(parsed);
          },
        ),

        const SizedBox(height: 20),

        // --- From / Swap / To ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // From currency
            Expanded(
              child: StyledDropdown<String>(
                label: '보내는 통화',
                value: state.fromCurrency,
                items: currencyLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 16)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(currencyProvider.notifier).setFromCurrency(v);
                  }
                },
              ),
            ),

            // Swap button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                onPressed: () {
                  ref.read(currencyProvider.notifier).swapCurrencies();
                },
                icon: const Icon(Icons.swap_horiz, size: 32),
                color: cs.primary,
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),

            // To currency
            Expanded(
              child: StyledDropdown<String>(
                label: '받는 통화',
                value: state.toCurrency,
                items: currencyLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 16)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(currencyProvider.notifier).setToCurrency(v);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // --- Rate Type Selector ---
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '환율 종류',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<RateType>(
                segments: const [
                  ButtonSegment(
                    value: RateType.standard,
                    label: Text('매매기준율', style: TextStyle(fontSize: 14)),
                  ),
                  ButtonSegment(
                    value: RateType.buy,
                    label: Text('살 때', style: TextStyle(fontSize: 14)),
                  ),
                  ButtonSegment(
                    value: RateType.sell,
                    label: Text('팔 때', style: TextStyle(fontSize: 14)),
                  ),
                ],
                selected: {state.rateType},
                onSelectionChanged: (v) {
                  ref.read(currencyProvider.notifier).setRateType(v.first);
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

        const SizedBox(height: 24),

        // --- Loading / Error ---
        if (state.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(color: cs.primary),
            ),
          ),

        if (state.error != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    color: cs.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.error!,
                    style: TextStyle(
                        fontSize: 15, color: cs.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),

        // --- Result ---
        if (state.result != null && !state.isLoading) ...[
          ResultDisplayCard(
            label:
                '${currencyLabels[state.fromCurrency] ?? state.fromCurrency} → ${currencyLabels[state.toCurrency] ?? state.toCurrency}',
            value: _fmt.format(state.result!),
            unit: state.toCurrency,
            accentColor: cs.primary,
          ),

          const SizedBox(height: 12),

          // Applied rate info
          if (state.appliedRate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '적용 환율',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '1 ${state.fromCurrency} = ${_rateFmt.format(state.appliedRate!)} ${state.toCurrency}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (state.lastUpdatedText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '기준 시각',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          state.lastUpdatedText,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}
