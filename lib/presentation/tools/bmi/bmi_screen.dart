import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  Color _categoryColor(String category) {
    switch (category) {
      case '저체중':
        return Colors.blue;
      case '정상':
        return Colors.green;
      case '과체중':
        return Colors.orange;
      case '비만 1단계':
        return Colors.deepOrange;
      case '비만 2단계':
        return Colors.red;
      case '고도비만':
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

    return ToolScaffold(
      title: '비만도 계산기',
      children: [
        // ── Inputs ──────────────────────────────────────
        LabeledInputField(
          label: '신장 (cm)',
          hint: '예: 170',
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
          label: '체중 (kg)',
          hint: '예: 65',
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
          label: '성별',
          value: state.gender,
          items: const [
            DropdownMenuItem(value: Gender.male, child: Text('남성')),
            DropdownMenuItem(value: Gender.female, child: Text('여성')),
          ],
          onChanged: (v) {
            if (v != null) notifier.setGender(v);
          },
        ),
        const SizedBox(height: 16),

        LabeledInputField(
          label: '나이 (세)',
          hint: '예: 45',
          suffix: '세',
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => notifier.setAge(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 28),

        // ── Results ─────────────────────────────────────
        if (state.bmi > 0) ...[
          ResultDisplayCard(
            label: 'BMI 지수',
            value: state.bmi.toStringAsFixed(1),
            accentColor: _categoryColor(state.category),
          ),
          const SizedBox(height: 12),

          // BMI Category with color
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _categoryColor(state.category).withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  'BMI 판정',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _categoryColor(state.category),
                  ),
                ),
                const Spacer(),
                Text(
                  state.category,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _categoryColor(state.category),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Visual BMI scale
          _buildBmiScale(state.bmi, cs),
          const SizedBox(height: 16),

          if (state.bmr > 0) ...[
            ResultDisplayCard(
              label: '기초대사량 (BMR)',
              value: _fmt.format(state.bmr),
              unit: 'kcal',
              accentColor: cs.primary,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _buildBmiScale(double bmi, ColorScheme cs) {
    final fraction = _bmiToFraction(bmi);
    final labels = ['저체중', '정상', '과체중', '비만1', '비만2', '고도비만'];
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
            'BMI 척도',
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
