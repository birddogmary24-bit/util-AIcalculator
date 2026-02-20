import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/labeled_input_field.dart';
import '../../common/widgets/result_display_card.dart';
import '../../common/widgets/styled_dropdown.dart';
import 'unit_provider.dart';

final _fmt = NumberFormat('#,##0.######');
String _formatResult(double v) {
  // If the value is very large or very small, use scientific-ish formatting
  if (v.abs() >= 1e9 || (v != 0 && v.abs() < 0.000001)) {
    return v.toStringAsPrecision(6);
  }
  return _fmt.format(v);
}

class UnitScreen extends ConsumerStatefulWidget {
  const UnitScreen({super.key});

  @override
  ConsumerState<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends ConsumerState<UnitScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(unitProvider);
    final units = unitData[state.category]!;
    final fromUnit = units.firstWhere((u) => u.id == state.fromUnitId);
    final toUnit = units.firstWhere((u) => u.id == state.toUnitId);

    return ToolScaffold(
      title: '단위 계산기',
      children: [
        // ── Category chips ───────────────────────────────────────────────
        _buildCategoryChips(state.category),

        const SizedBox(height: 24),

        // ── From unit ────────────────────────────────────────────────────
        StyledDropdown<String>(
          label: '변환할 단위',
          value: state.fromUnitId,
          items: units
              .map((u) => DropdownMenuItem<String>(
                    value: u.id,
                    child: Text(
                      '${u.label} (${u.symbol})',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) ref.read(unitProvider.notifier).setFromUnit(v);
          },
        ),

        const SizedBox(height: 16),

        // ── Input value ──────────────────────────────────────────────────
        LabeledInputField(
          label: '값 입력',
          hint: '숫자를 입력하세요',
          suffix: fromUnit.symbol,
          controller: _inputController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
            ref.read(unitProvider.notifier).setInputValue(parsed);
          },
        ),

        const SizedBox(height: 16),

        // ── Swap button ──────────────────────────────────────────────────
        Center(
          child: Material(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ref.read(unitProvider.notifier).swapUnits();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert, size: 28, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      '단위 바꾸기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── To unit ──────────────────────────────────────────────────────
        StyledDropdown<String>(
          label: '결과 단위',
          value: state.toUnitId,
          items: units
              .map((u) => DropdownMenuItem<String>(
                    value: u.id,
                    child: Text(
                      '${u.label} (${u.symbol})',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) ref.read(unitProvider.notifier).setToUnit(v);
          },
        ),

        const SizedBox(height: 24),

        // ── Result display ───────────────────────────────────────────────
        ResultDisplayCard(
          label: '변환 결과',
          value: state.result != null ? _formatResult(state.result!) : '0',
          unit: toUnit.symbol,
          accentColor: cs.primary,
        ),
      ],
    );
  }

  // ── Category chip bar ──────────────────────────────────────────────────────

  Widget _buildCategoryChips(UnitCategory selected) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: UnitCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = UnitCategory.values[index];
          final isSelected = cat == selected;
          return ChoiceChip(
            label: Text(
              categoryLabels[cat]!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              _inputController.clear();
              ref.read(unitProvider.notifier).setCategory(cat);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        },
      ),
    );
  }
}
