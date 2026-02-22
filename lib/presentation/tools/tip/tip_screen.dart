import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../core/utils/thousands_input_formatter.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import 'tip_provider.dart';

final _fmt = NumberFormat('#,##0.##');
String _formatNumber(double v) => _fmt.format(v);

class TipScreen extends ConsumerStatefulWidget {
  const TipScreen({super.key});

  @override
  ConsumerState<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends ConsumerState<TipScreen> {
  final _billController = TextEditingController();

  static const _presetTips = [15.0, 18.0, 20.0, 25.0];

  @override
  void dispose() {
    _billController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(tipProvider);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;
    final currencyUnit = isKr ? '원' : '\$';

    return ToolScaffold(
      title: isKr ? '팁 계산기' : 'Tip Calculator',
      children: [
        // Bill amount input
        LabeledInputField(
          label: isKr ? '금액' : 'Bill Amount',
          hint: isKr ? '금액을 입력하세요' : 'Enter bill amount',
          suffix: currencyUnit,
          controller: _billController,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(tipProvider.notifier).setBillAmount(parsed);
          },
        ),

        const SizedBox(height: 20),

        // Tip % presets
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '팁 비율' : 'Tip Percentage',
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
              children: _presetTips.map((pct) {
                final isSelected =
                    (state.tipPercent - pct).abs() < 0.01;
                return ChoiceChip(
                  label: Text('${pct.toStringAsFixed(0)}%'),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(tipProvider.notifier).setTipPercent(pct);
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

        const SizedBox(height: 16),

        // Custom tip slider
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isKr ? '직접 입력' : 'Custom Tip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${state.tipPercent.toStringAsFixed(1)}%',
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
                value: state.tipPercent.clamp(0, 50),
                min: 0,
                max: 50,
                divisions: 100,
                label: '${state.tipPercent.toStringAsFixed(1)}%',
                onChanged: (v) {
                  ref.read(tipProvider.notifier).setTipPercent(v);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Split count
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKr ? '인원수' : 'Split Between',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundButton(
                    icon: Icons.remove,
                    onPressed: state.splitCount > 1
                        ? () =>
                            ref.read(tipProvider.notifier).decrementSplit()
                        : null,
                    color: cs.primary,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      '${state.splitCount}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  _RoundButton(
                    icon: Icons.add,
                    onPressed: () =>
                        ref.read(tipProvider.notifier).incrementSplit(),
                    color: cs.primary,
                  ),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  isKr
                      ? '${state.splitCount}명'
                      : '${state.splitCount} ${state.splitCount == 1 ? 'person' : 'people'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Results
        ResultDisplayCard(
          label: isKr ? '팁 금액' : 'Tip Amount',
          value: _formatNumber(state.tipAmount),
          unit: currencyUnit,
          accentColor: cs.tertiary,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: isKr ? '합계' : 'Total',
          value: _formatNumber(state.totalAmount),
          unit: currencyUnit,
          accentColor: cs.primary,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: isKr ? '1인당' : 'Per Person',
          value: _formatNumber(state.perPerson),
          unit: currencyUnit,
          accentColor: cs.secondary,
        ),
      ],
    );
  }
}

/// A small circular icon button used for increment / decrement controls.
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _RoundButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Material(
      color: isDisabled ? color.withAlpha(30) : color.withAlpha(50),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 24,
            color: isDisabled ? color.withAlpha(80) : color,
          ),
        ),
      ),
    );
  }
}
