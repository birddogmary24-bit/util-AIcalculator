import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    return ToolScaffold(
      title: '할인 계산기',
      children: [
        // 원래 가격 입력
        LabeledInputField(
          label: '원래 가격',
          hint: '가격을 입력하세요',
          suffix: '원',
          controller: _priceController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(discountProvider.notifier).setOriginalPrice(parsed);
          },
        ),

        const SizedBox(height: 20),

        // 할인율 입력
        LabeledInputField(
          label: '할인율',
          hint: '할인율을 입력하세요',
          suffix: '%',
          controller: _percentController,
          onChanged: (v) {
            final parsed = double.tryParse(v) ?? 0;
            ref.read(discountProvider.notifier).setDiscountPercent(parsed);
          },
        ),

        const SizedBox(height: 12),

        // 할인율 슬라이더
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '슬라이더로 조절',
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

        // 결과 표시
        ResultDisplayCard(
          label: '할인 금액',
          value: _formatNumber(state.savedAmount),
          unit: '원',
          accentColor: cs.error,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: '할인 후 가격',
          value: _formatNumber(state.finalPrice),
          unit: '원',
          accentColor: cs.primary,
        ),
      ],
    );
  }
}
