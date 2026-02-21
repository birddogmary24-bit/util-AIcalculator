import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/region.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import '../../common/widgets/styled_dropdown.dart';
import 'bmi_provider.dart';

class BmiScreen extends ConsumerStatefulWidget {
  const BmiScreen({super.key});

  @override
  ConsumerState<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends ConsumerState<BmiScreen> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _fmt = NumberFormat('#,##0.##');

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(String categoryKey) {
    switch (categoryKey) {
      case 'underweight':
        return Colors.blue;
      case 'normal':
        return Colors.green;
      case 'overweight':
        return Colors.orange;
      case 'obese1':
        return Colors.deepOrange;
      case 'obese2':
        return Colors.red;
      case 'morbid':
        return Colors.red.shade900;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  double _bmiToFraction(double bmi) {
    // Map BMI 10~40 range to 0.0~1.0
    return ((bmi - 10) / 30).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(bmiProvider);
    final notifier = ref.read(bmiProvider.notifier);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;

    return ToolScaffold(
      title: isKr ? '비만도 계산기' : 'BMI Calculator',
      children: [
        // ── Inputs ──────────────────────────────────────
        LabeledInputField(
          label: isKr ? '신장 (cm)' : 'Height (cm)',
          hint: isKr ? '예: 170' : 'e.g. 170',
          suffix: 'cm',
          controller: _heightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          onChanged: (v) => notifier.setHeight(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 16),

        LabeledInputField(
          label: isKr ? '체중 (kg)' : 'Weight (kg)',
          hint: isKr ? '예: 65' : 'e.g. 65',
          suffix: 'kg',
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          onChanged: (v) => notifier.setWeight(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 16),

        StyledDropdown<Gender>(
          label: isKr ? '성별' : 'Gender',
          value: state.gender,
          items: [
            DropdownMenuItem(
              value: Gender.male,
              child: Text(isKr ? '남성' : 'Male'),
            ),
            DropdownMenuItem(
              value: Gender.female,
              child: Text(isKr ? '여성' : 'Female'),
            ),
          ],
          onChanged: (v) {
            if (v != null) notifier.setGender(v);
          },
        ),
        const SizedBox(height: 16),

        LabeledInputField(
          label: isKr ? '나이 (세)' : 'Age (years)',
          hint: isKr ? '예: 45' : 'e.g. 45',
          suffix: isKr ? '세' : 'yrs',
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => notifier.setAge(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 28),

        // ── Results ─────────────────────────────────────
        if (state.bmi > 0) ...[
          ResultDisplayCard(
            label: isKr ? 'BMI 지수' : 'BMI Score',
            value: _fmt.format(state.bmi),
            accentColor: _categoryColor(state.categoryKey),
          ),
          const SizedBox(height: 12),

          // BMI Category with color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _categoryColor(state.categoryKey).withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  isKr ? 'BMI 판정' : 'BMI Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _categoryColor(state.categoryKey),
                  ),
                ),
                const Spacer(),
                Text(
                  state.categoryLabel(region),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _categoryColor(state.categoryKey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Visual BMI scale
          _buildBmiScale(state.bmi, cs, region),
          const SizedBox(height: 16),

          if (state.bmr > 0) ...[
            ResultDisplayCard(
              label: isKr ? '기초대사량 (BMR)' : 'Basal Metabolic Rate (BMR)',
              value: _fmt.format(state.bmr),
              unit: isKr ? 'kcal' : 'kcal/day',
              accentColor: cs.primary,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _buildBmiScale(double bmi, ColorScheme cs, RegionMode region) {
    final fraction = _bmiToFraction(bmi);
    final isKr = region == RegionMode.kr;
    final labels = isKr
        ? ['저체중', '정상', '과체중', '비만1', '비만2', '고도비만']
        : ['Under', 'Normal', 'Over', 'Obese I', 'Obese II', 'Morbid'];
    final thresholds = [18.5, 23.0, 25.0, 30.0, 35.0];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
      Colors.red.shade900,
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
            isKr ? 'BMI 척도' : 'BMI Scale',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Scale bar
          SizedBox(
            height: 28,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final indicatorPos = fraction * totalWidth;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Colored segments
                    Row(
                      children: [
                        // 10~18.5 -> 28.3%
                        _scaleSegment(colors[0], 8.5 / 30),
                        // 18.5~23 -> 15%
                        _scaleSegment(colors[1], 4.5 / 30),
                        // 23~25 -> 6.7%
                        _scaleSegment(colors[2], 2.0 / 30),
                        // 25~30 -> 16.7%
                        _scaleSegment(colors[3], 5.0 / 30),
                        // 30~35 -> 16.7%
                        _scaleSegment(colors[4], 5.0 / 30),
                        // 35~40 -> 16.7%
                        _scaleSegment(colors[5], 5.0 / 30),
                      ],
                    ),
                    // Indicator triangle
                    Positioned(
                      left: indicatorPos.clamp(6, totalWidth - 6) - 6,
                      top: -4,
                      child: Icon(
                        Icons.arrow_drop_down,
                        size: 36,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // Labels row
          Row(
            children: [
              for (int i = 0; i < labels.length; i++) ...[
                Expanded(
                  flex: i == 0
                      ? 85
                      : i == 1
                          ? 45
                          : i == 2
                              ? 20
                              : 50,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors[i],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Threshold numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              for (final t in thresholds)
                Text(t.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 10, color: cs.onSurfaceVariant)),
              Text('40+',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scaleSegment(Color color, double flex) {
    return Expanded(
      flex: (flex * 1000).round(),
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
