import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';

enum CalcButtonType { number, operator, function, equal, zero, clear }

class CalcButton extends StatefulWidget {
  final String label;
  final CalcButtonType type;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double? fontSize;

  const CalcButton({
    super.key,
    required this.label,
    required this.type,
    required this.onTap,
    this.onLongPress,
    this.fontSize,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;

    switch (widget.type) {
      case CalcButtonType.operator:
        bgColor = AppColors.operatorBtn;
        fgColor = Colors.white;
      case CalcButtonType.equal:
        bgColor = AppColors.equalBtn;
        fgColor = Colors.white;
      case CalcButtonType.clear:
        bgColor = AppColors.clearBtn;
        fgColor = Colors.white;
      case CalcButtonType.function:
        bgColor = AppColors.funcBtn;
        fgColor = Colors.black87;
      case CalcButtonType.number:
      case CalcButtonType.zero:
        bgColor = AppColors.numBtn;
        fgColor = Colors.black87;
    }

    // Pressed: darken + shift down + flatten shadow
    final pressedColor = Color.lerp(bgColor, Colors.black, 0.22)!;
    final displayColor = _pressed ? pressedColor : bgColor;

    // Hard shadow — physical button depth, no blur
    final shadow = _pressed
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              offset: const Offset(0, 4),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ];

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              widget.onLongPress!();
            }
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final btnHeight = constraints.maxHeight;
          const radius = 10.0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: size,
            height: btnHeight,
            transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
            decoration: BoxDecoration(
              color: displayColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: const Color(0xFF8A8A8A), width: 1.5),
              boxShadow: shadow,
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: TextStyle(
                color: fgColor,
                fontSize: widget.fontSize ?? size * 0.473,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          );
        },
      ),
    );
  }
}
