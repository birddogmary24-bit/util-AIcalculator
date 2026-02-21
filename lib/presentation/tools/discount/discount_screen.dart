import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../core/utils/thousands_input_formatter.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import 'discount_provider.dart';

final _fmt = NumberFormat('#,##0.##');
String _formatNumber(double v) => _fmt.format(v);

class DiscountScreen extends ConsumerStatefulWidget {
  const DiscountScreen({super.key});

  @override
  ConsumerState<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends ConsumerState<DiscountScreen> {
  final _priceController = TextEditingController();
  final _percentController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(discountProvider);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : '\$';

    return ToolScaffold(
      title: isKr ? '할인 계산기' : 'Discount Calculator',
      children: [
        // Original price input
        LabeledInputField(
          label: isKr ? '원래 가격' : 'Original Price',
          hint: isKr ? '가격을 입력하세요' : 'Enter price',
          suffix: currencyUnit,
          controller: _priceController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(discountProvider.notifier).setOriginalPrice(parsed);
          },
        ),

        const SizedBox(height: 20),

        // Discount rate input
        LabeledInputField(
          label: isKr ? '할인율' : 'Discount Rate',
          hint: isKr ? '할인율을 입력하세요' : 'Enter discount rate',
          suffix: '%',
          controller: _percentController,
          onChanged: (v) {
            final parsed = double.tryParse(v) ?? 0;
            ref.read(discountProvider.notifier).setDiscountPercent(parsed);
          },
        ),

        const SizedBox(height: 12),

        // Discount slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isKr ? '슬라이더로 조절' : 'Adjust with slider',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${state.discountPercent.toStringAsFixed(0)}%',
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
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: state.discountPercent.clamp(0, 100),
                min: 0,
                max: 100,
                divisions: 100,
                label: '${state.discountPercent.toStringAsFixed(0)}%',
                onChanged: (v) {
                  _percentController.text = v.toStringAsFixed(0);
                  ref.read(discountProvider.notifier).setDiscountPercent(v);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Results
        ResultDisplayCard(
          label: isKr ? '할인 금액' : 'Discount Amount',
          value: _formatNumber(state.savedAmount),
          unit: currencyUnit,
          accentColor: cs.error,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: isKr ? '할인 후 가격' : 'Final Price',
          value: _formatNumber(state.finalPrice),
          unit: currencyUnit,
          accentColor: cs.primary,
        ),
      ],
    );
  }
}
