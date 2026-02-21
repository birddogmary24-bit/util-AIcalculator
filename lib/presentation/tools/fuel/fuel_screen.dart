import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../providers/region_provider.dart';
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
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;

    return ToolScaffold(
      title: isKr ? '연비 계산기' : 'Fuel Calculator',
      children: [
        // Distance input
        LabeledInputField(
          label: isKr ? '주행거리' : 'Distance',
          hint: isKr ? '주행거리를 입력하세요' : 'Enter distance',
          suffix: 'km',
          controller: _distanceController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(fuelProvider.notifier).setDistance(parsed);
          },
        ),

        const SizedBox(height: 20),

        // Fuel amount input
        LabeledInputField(
          label: isKr ? '주유량' : 'Fuel Amount',
          hint: isKr ? '주유량을 입력하세요' : 'Enter fuel amount',
          suffix: 'L',
          controller: _fuelController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(fuelProvider.notifier).setFuelUsed(parsed);
          },
        ),

        const SizedBox(height: 20),

        // Gas price input
        LabeledInputField(
          label: isKr ? '유가' : 'Gas Price',
          hint: isKr ? '리터당 가격을 입력하세요' : 'Enter price per liter',
          suffix: isKr ? '원/L' : '/L',
          controller: _gasPriceController,
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(fuelProvider.notifier).setGasPrice(parsed);
          },
        ),

        const SizedBox(height: 24),

        // Results
        ResultDisplayCard(
          label: isKr ? '연비' : 'Fuel Efficiency',
          value: _formatNumber(state.fuelEfficiency),
          unit: 'km/L',
          accentColor: cs.primary,
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: isKr ? 'km당 비용' : 'Cost per km',
          value: _formatNumber(state.costPerKm),
          unit: isKr ? '원/km' : '/km',
        ),

        const SizedBox(height: 12),

        ResultDisplayCard(
          label: isKr ? '총 연료비' : 'Total Fuel Cost',
          value: _formatNumber(state.totalFuelCost),
          unit: isKr ? '원' : '',
          accentColor: cs.error,
        ),
      ],
    );
  }
}
