import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/number_formatter.dart';

class DisplayPanel extends StatelessWidget {
  final String display;
  final String expression;
  final bool isAiLoading;

  const DisplayPanel({
    super.key,
    required this.display,
    required this.expression,
    this.isAiLoading = false,
  });

  String get _formattedDisplay {
    if (display == '계산 오류') return display;
    final num = double.tryParse(display);
    if (num != null) return NumberFormatter.format(num);
    // Partial input (e.g. "123.")
    return NumberFormatter.formatDisplay(display);
  }

  double _fontSize(String text) {
    if (text.length <= 6) return 64;
    if (text.length <= 9) return 52;
    if (text.length <= 12) return 40;
    return 30;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.displayBg : AppColors.displayBgLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expression row
          if (expression.isNotEmpty)
            Text(
              expression,
              style: const TextStyle(
                color: AppColors.expressionText,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          if (expression.isNotEmpty) const SizedBox(height: 4),

          // Result row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isAiLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  _formattedDisplay,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.resultText
                        : AppColors.resultTextLight,
                    fontSize: _fontSize(_formattedDisplay),
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(text: _formattedDisplay),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _copied
              ? AppColors.primary.withAlpha(40)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.expressionText.withAlpha(80),
            width: 1,
          ),
        ),
        child: Text(
          _copied ? '복사됨' : '복사',
          style: const TextStyle(
            color: AppColors.expressionText,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
