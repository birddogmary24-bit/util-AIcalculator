import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../core/utils/thousands_input_formatter.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import 'sales_tax_provider.dart';

final _fmt = NumberFormat('#,##0.##');
String _formatNumber(double v) => _fmt.format(v);

class SalesTaxScreen extends ConsumerStatefulWidget {
  const SalesTaxScreen({super.key});

  @override
  ConsumerState<SalesTaxScreen> createState() => _SalesTaxScreenState();
}

class _SalesTaxScreenState extends ConsumerState<SalesTaxScreen> {
  final _priceController = TextEditingController();
  final _rateController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(salesTaxProvider);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : '\$';

    // Sync rate text field when preset is selected
    ref.listen<SalesTaxState>(salesTaxProvider, (prev, next) {
      if (prev?.selectedPreset != next.selectedPreset &&
          next.selectedPreset != null) {
        _rateController.text = next.taxRate.toString();
      }
    });

    return ToolScaffold(
      title: isKr ? '판매세 계산기' : 'Sales Tax Calculator',
      children: [
        // Price input
        LabeledInputField(
          label: isKr ? '가격' : 'Price',
          hint: isKr ? '가격을 입력하세요' : 'Enter price',
          suffix: currencyUnit,
          controller: _priceController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(salesTaxProvider.notifier).setPrice(parsed);
          },
        ),

        const SizedBox(height: 20),

        // Tax rate presets
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '주요 세율' : 'State Tax Presets',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: taxPresets.map((preset) {
                final isSelected = state.selectedPreset == preset.name;
                return ChoiceChip(
                  label: Text(
                    '${preset.name} (${preset.rate}%)',
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(salesTaxProvider.notifier).selectPreset(preset);
                  },
                  selectedColor: cs.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Custom tax rate
        LabeledInputField(
          label: isKr ? '세율' : 'Tax Rate',
          hint: isKr ? '세율을 입력하세요' : 'Enter custom tax rate',
          suffix: '%',
          controller: _rateController,
          onChanged: (v) {
            final parsed = double.tryParse(v) ?? 0;
            ref.read(salesTaxProvider.notifier).setTaxRate(parsed);
          },
        ),

        const SizedBox(height: 12),

        // Tax rate slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isKr ? '슬라이더로 조절' : 'Adjust with Slider',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${state.taxRate.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.outlineVariant,
                thumbColor: cs.primary,
                overlayColor: cs.primary.withAlpha(40),
                trackHeight: 6,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: state.taxRate.clamp(0, 15),
                min: 0,
                max: 15,
                divisions: 150,
                label: '${state.taxRate.toStringAsFixed(2)}%',
                onChanged: (v) {
                  final rounded =
                      (v * 100).roundToDouble() / 100; // 0.01 precision
                  _rateController.text = rounded.toString();
                  ref.read(salesTaxProvider.notifier).setTaxRate(rounded);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Results
        ResultDisplayCard(
          label: isKr ? '세금' : 'Tax Amount',
          value: _formatNumber(state.taxAmount),
          unit: currencyUnit,
          accentColor: cs.error,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: isKr ? '총 가격' : 'Total Price',
          value: _formatNumber(state.totalPrice),
          unit: currencyUnit,
          accentColor: cs.primary,
        ),
      ],
    );
  }
}
