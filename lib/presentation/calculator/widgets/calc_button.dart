import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

enum CalcButtonType { number, operator, function, equal, zero }

class CalcButton extends StatelessWidget {
  final String label;
  final CalcButtonType type;
  final VoidCallback onTap;

  const CalcButton({
    super.key,
    required this.label,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;

    switch (type) {
      case CalcButtonType.operator:
      case CalcButtonType.equal:
        bgColor = AppColors.operator_;
        fgColor = Colors.white;
      case CalcButtonType.function:
        bgColor = isDark ? AppColors.funcBtnDark : AppColors.funcBtn;
        fgColor = isDark ? Colors.white : Colors.black;
      case CalcButtonType.number:
      case CalcButtonType.zero:
        bgColor = isDark ? AppColors.numBtn : AppColors.numBtnDark.withAlpha(30);
        fgColor = isDark ? Colors.white : Colors.black;
    }

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: type == CalcButtonType.zero
                  ? BoxShape.rectangle
                  : BoxShape.circle,
              borderRadius: type == CalcButtonType.zero
                  ? BorderRadius.circular(size / 2)
                  : null,
            ),
            alignment: type == CalcButtonType.zero
                ? Alignment.centerLeft
                : Alignment.center,
            padding: type == CalcButtonType.zero
                ? EdgeInsets.only(left: size * 0.35)
                : EdgeInsets.zero,
            child: Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }
}
