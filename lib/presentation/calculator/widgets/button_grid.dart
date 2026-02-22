import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/region.dart';
import '../../../core/utils/calculator_engine.dart';
import '../../../domain/models/button_definition.dart';
import '../../../providers/button_config_provider.dart';
import '../../../providers/region_provider.dart';
import '../calculator_provider.dart';
import 'button_swap_modal.dart';
import 'calc_button.dart';

class ButtonGrid extends ConsumerWidget {
  final VoidCallback? onAiTap;
  const ButtonGrid({super.key, this.onAiTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(calculatorProvider.notifier);
    final calcState = ref.watch(calculatorProvider);
    final layout = ref.watch(buttonConfigProvider);
    final region = ref.watch(regionProvider);
    final s = AppStrings.of(region);
    final isAllClear =
        calcState.display == '0' && calcState.expression.isEmpty;
    final openParens = calcState.openParens;

    // Collect all currently placed button IDs
    final currentIds = <String>{};
    for (final row in layout) {
      currentIds.addAll(row);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const gap = 10.0;
        const utilityGap = 3.5;
        final btnSize = (totalWidth - gap * 3) / 4;

        return Column(
          children: [
            // Utility row — no container, no hint text
            Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: LayoutBuilder(
                builder: (ctx, innerConstraints) {
                  return _buildUtilityRow(ctx, ref, notifier, innerConstraints.maxWidth, utilityGap, currentIds, region, s);
                },
              ),
            ),
            // Main button grid
            ...List.generate(layout.length, (rowIdx) {
              final row = layout[rowIdx];
              // First row (AC, +/-, %, ÷) is 10% shorter; rows 1-4 get taller to absorb freed bottom space
              final rowBtnHeight = rowIdx == 0 ? btnSize * 0.675 : btnSize * 0.82;
              final buttons = List.generate(row.length, (colIdx) {
                final btnId = row[colIdx];
                return _buildButton(
                  context: context,
                  ref: ref,
                  notifier: notifier,
                  btnId: btnId,
                  btnSize: btnSize,
                  btnHeight: rowBtnHeight,
                  isAllClear: isAllClear,
                  openParens: openParens,
                  rowIdx: rowIdx,
                  colIdx: colIdx,
                  currentIds: currentIds,
                  region: region,
                );
              });
              return Padding(
                padding: EdgeInsets.only(bottom: rowIdx < layout.length - 1 ? gap : 0),
                child: _buildRow(btnSize, rowBtnHeight, gap, buttons),
              );
            }),
            // Bottom breathing room: ~30% of number button height
            SizedBox(height: btnSize * 0.82 * 0.3),
          ],
        );
      },
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required WidgetRef ref,
    required CalculatorNotifier notifier,
    required String btnId,
    required double btnSize,
    required double btnHeight,
    required bool isAllClear,
    required int openParens,
    required int rowIdx,
    required int colIdx,
    required Set<String> currentIds,
    required RegionMode region,
  }) {
    final def = getButtonDef(btnId);
    if (def == null) {
      return SizedBox(width: btnSize, height: btnHeight);
    }

    // Determine dynamic label for special cases
    String label;
    if (btnId == 'clear') {
      label = isAllClear ? 'AC' : 'C';
    } else if (btnId == 'paren') {
      label = openParens > 0 ? ')' : '( )';
    } else {
      // Use localized label for tool buttons, fallback for others
      label = def.localizedLabel(region);
    }

    // Determine tap action
    final onTap = _resolveAction(context, ref, notifier, def);

    // Font size: smaller for tool buttons with longer labels
    final isToolBtn = def.action == ButtonAction.navigate;
    final fontSize = isToolBtn ? btnSize * 0.28 : null;

    return CalcButton(
      label: label,
      type: def.type,
      onTap: onTap,
      fontSize: fontSize,
      onLongPress: () async {
        final selected = await showButtonSwapModal(
          context,
          currentIds: currentIds,
          region: region,
        );
        if (selected == null) return;
        if (isResetResult(selected)) {
          await ref.read(buttonConfigProvider.notifier).resetToDefault();
        } else {
          await ref
              .read(buttonConfigProvider.notifier)
              .swapButton(rowIdx, colIdx, selected);
        }
      },
    );
  }

  VoidCallback _resolveAction(
    BuildContext context,
    WidgetRef ref,
    CalculatorNotifier notifier,
    CalcButtonDef def,
  ) {
    switch (def.action) {
      case ButtonAction.digit:
        return () => notifier.inputDigit(def.param!);
      case ButtonAction.operator:
        return () {
          final op = _parseOp(def.param!);
          notifier.inputOperator(op);
        };
      case ButtonAction.function:
        switch (def.param) {
          case 'toggle_sign':
            return notifier.toggleSign;
          case 'percent':
            return notifier.percentage;
          case 'paren':
            return notifier.inputParen;
          default:
            return () {};
        }
      case ButtonAction.calculate:
        return notifier.calculate;
      case ButtonAction.clear:
        final calcState = ref.read(calculatorProvider);
        final isAllClear =
            calcState.display == '0' && calcState.expression.isEmpty;
        return isAllClear ? notifier.allClear : notifier.clear;
      case ButtonAction.navigate:
        return () => context.push(def.param!);
      case ButtonAction.special:
        switch (def.param) {
          case 'sqrt':
            return () => notifier.squareRoot();
          case 'ai':
            // Focus on the natural language input bar
            return () {
              FocusScope.of(context).nextFocus();
            };
          default:
            return () {};
        }
    }
  }

  CalcOp _parseOp(String param) {
    switch (param) {
      case 'add':
        return CalcOp.add;
      case 'subtract':
        return CalcOp.subtract;
      case 'multiply':
        return CalcOp.multiply;
      case 'divide':
        return CalcOp.divide;
      default:
        return CalcOp.none;
    }
  }

  Widget _buildRow(double btnSize, double btnHeight, double gap, List<Widget> buttons) {
    return Row(
      children: buttons
          .map((btn) =>
              SizedBox(width: btnSize, height: btnHeight, child: btn))
          .expand((w) => [w, SizedBox(width: gap)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildUtilityRow(
    BuildContext context,
    WidgetRef ref,
    CalculatorNotifier notifier,
    double totalWidth,
    double gap,
    Set<String> currentIds,
    RegionMode region,
    Map<String, String> s,
  ) {
    final utilityConfig = ref.watch(utilityButtonConfigProvider);
    // Layout: [Reset] [Slot1] [Slot2] [Slot3] | [AI]
    // 5 buttons + 4 gaps + divider area (1px + 4px padding each side = 9px total)
    const dividerTotalWidth = 9.0;
    final btnWidth = (totalWidth - gap * (utilitySlotCount - 1) - dividerTotalWidth) / utilitySlotCount;
    const btnHeight = 34.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizedPlaceholders = getUtilityPlaceholders(region);

    // ── Slot 0: Reset ────────────────────────────────────────────────────
    final resetBtn = SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: GestureDetector(
        onTap: () async {
          await ref.read(buttonConfigProvider.notifier).resetToDefault();
          await ref.read(utilityButtonConfigProvider.notifier).resetAll();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A4870) : const Color(0xFF4A5882),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            region == RegionMode.kr ? '초기화' : 'Reset',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    // ── Slots 1–3: Configurable ──────────────────────────────────────────
    final configSlots = List.generate(3, (i) {
      final index = i + 1; // slots 1, 2, 3
      final configuredId = utilityConfig[index];
      final def = configuredId != null ? getButtonDef(configuredId) : null;
      final isConfigured = def != null;
      final label = isConfigured
          ? def.localizedLabel(region)
          : localizedPlaceholders[index];

      return SizedBox(
        width: btnWidth,
        height: btnHeight,
        child: _UtilitySlotButton(
          label: label,
          isConfigured: isConfigured,
          isDark: isDark,
          onTap: () {
            if (isConfigured) {
              final action = _resolveAction(context, ref, notifier, def);
              action();
            } else {
              _openUtilitySwapModal(context, ref, index, currentIds, region);
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _openUtilitySwapModal(context, ref, index, currentIds, region);
          },
        ),
      );
    });

    // ── Slot 4: AI (fixed, Gemini colors) ────────────────────────────────
    final aiBtn = SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: _GeminiAiButton(
        isDark: isDark,
        onTap: onAiTap,
      ),
    );

    // ── Divider between slot3 and AI ─────────────────────────────────────
    final divider = SizedBox(
      width: dividerTotalWidth,
      height: btnHeight,
      child: Center(
        child: Container(
          width: 1,
          height: btnHeight * 0.55,
          color: isDark ? Colors.white24 : Colors.black26,
        ),
      ),
    );

    return Row(
      children: [
        resetBtn,
        SizedBox(width: gap),
        ...configSlots.expand((w) => [w, SizedBox(width: gap)]),
        divider,
        aiBtn,
      ],
    );
  }

  Future<void> _openUtilitySwapModal(
    BuildContext context,
    WidgetRef ref,
    int slotIndex,
    Set<String> currentIds,
    RegionMode region,
  ) async {
    final selected = await showButtonSwapModal(
      context,
      currentIds: currentIds,
      region: region,
    );
    if (selected == null) return;
    if (isResetResult(selected)) {
      await ref.read(utilityButtonConfigProvider.notifier).resetAll();
    } else {
      await ref.read(utilityButtonConfigProvider.notifier).setButton(slotIndex, selected);
    }
  }
}

// ── Gemini AI 버튼 (유틸리티 행 고정 슬롯) ──────────────────────────────────

class _GeminiAiButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onTap;

  const _GeminiAiButton({required this.isDark, this.onTap});

  @override
  State<_GeminiAiButton> createState() => _GeminiAiButtonState();
}

class _GeminiAiButtonState extends State<_GeminiAiButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.onTap != null;
    final pressedDarken = _pressed ? 0.18 : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(const Color(0xFF4285F4), Colors.black, pressedDarken)!,
                    Color.lerp(const Color(0xFF9C4FEA), Colors.black, pressedDarken)!,
                    Color.lerp(const Color(0xFFEA4335), Colors.black, pressedDarken)!,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                )
              : null,
          color: isActive ? null : (widget.isDark ? const Color(0xFF3A3D45) : const Color(0xFFE8E8EC)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive && !_pressed
              ? [
                  BoxShadow(
                    color: const Color(0xFF9C4FEA).withAlpha(100),
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          'AI',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.white : (widget.isDark ? Colors.white38 : Colors.black38),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── 유틸리티 슬롯 버튼 (설정됨: 하늘색 볼록, 미설정: 평면 회색) ──────────────

class _UtilitySlotButton extends StatefulWidget {
  final String label;
  final bool isConfigured;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _UtilitySlotButton({
    required this.label,
    required this.isConfigured,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_UtilitySlotButton> createState() => _UtilitySlotButtonState();
}

class _UtilitySlotButtonState extends State<_UtilitySlotButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // ── 색상 정의 ──────────────────────────────────────────────────
    // 설정됨: 하늘색 계열 (초기화 버튼의 남색과 구분)
    final configuredBg =
        widget.isDark ? const Color(0xFF1A6A8A) : const Color(0xFF3BA8CC);
    final configuredBorder =
        widget.isDark ? const Color(0xFF2A9ABF) : const Color(0xFF2890B2);
    final configuredShadow =
        widget.isDark ? const Color(0xFF0D3D52) : const Color(0xFF1A6A8A);

    // 미설정: 평면 회색
    final emptyBg =
        widget.isDark ? const Color(0xFF3A3D45) : const Color(0xFFE8E8EC);
    final emptyBorder =
        widget.isDark ? const Color(0xFF555555) : const Color(0xFFCCCCCC);

    final bgColor = widget.isConfigured ? configuredBg : emptyBg;
    final pressedColor = Color.lerp(bgColor, Colors.black, 0.20)!;
    final displayColor = _pressed ? pressedColor : bgColor;

    // 볼록 섀도우: 설정됨일 때만 하드 섀도우 적용
    final shadow = widget.isConfigured && !_pressed
        ? [
            BoxShadow(
              color: configuredShadow.withAlpha(200),
              offset: const Offset(0, 3),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ]
        : <BoxShadow>[];

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          widget.isConfigured ? (_pressed ? 3 : 0) : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: displayColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isConfigured ? configuredBorder : emptyBorder,
            width: widget.isConfigured ? 1.5 : 1.0,
          ),
          boxShadow: shadow,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.isConfigured
                ? Colors.white
                : (widget.isDark ? Colors.white54 : Colors.black45),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
