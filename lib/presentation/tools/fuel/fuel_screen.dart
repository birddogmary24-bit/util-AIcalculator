import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import 'fuel_provider.dart';

final _fmt = NumberFormat('#,##0.##');
String _formatNumber(double v) => _fmt.format(v);

class FuelScreen extends ConsumerStatefulWidget {
  const FuelScreen({super.key});

  @override
  ConsumerState<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends ConsumerState<FuelScreen> {
  final _distanceController = TextEditingController();
  final _fuelController = TextEditingController();
  final _gasPriceController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    _fuelController.dispose();
    _gasPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(fuelProvider);

    return ToolScaffold(
      title: '연비 계산기',
      children: [
        // 주행거리 입력
        LabeledInputField(
          label: '주행거리',
          hint: '주행거리를 입력하세요',
          suffix: 'km',
          controller: _distanceController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(fuelProvider.notifier).setDistance(parsed);
          },
        ),

        const SizedBox(height: 20),

        // 주유량 입력
        LabeledInputField(
          label: '주유량',
          hint: '주유량을 입력하세요',
          suffix: 'L',
          controller: _fuelController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(fuelProvider.notifier).setFuelUsed(parsed);
          },
        ),

        const SizedBox(height: 20),

        // 유가 입력
        LabeledInputField(
          label: '유가',
          hint: '리터당 가격을 입력하세요',
          suffix: '원/L',
          controller: _gasPriceController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(fuelProvider.notifier).setGasPrice(parsed);
          },
        ),

        const SizedBox(height: 24),

        // 결과 표시
        ResultDisplayCard(
          label: '연비',
          value: _formatNumber(state.fuelEfficiency),
          unit: 'km/L',
          accentColor: cs.primary,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: 'km당 비용',
          value: _formatNumber(state.costPerKm),
          unit: '원/km',
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: '총 연료비',
          value: _formatNumber(state.totalFuelCost),
          unit: '원',
          accentColor: cs.error,
        ),
      ],
    );
  }
}
