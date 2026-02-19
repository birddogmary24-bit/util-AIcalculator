import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class AiTipCard extends StatelessWidget {
  final String tip;
  final VoidCallback onDismiss;

  const AiTipCard({
    super.key,
    required this.tip,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.aiTipBg : AppColors.aiTipBgLight;

    return Dismissible(
      key: ValueKey(tip),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.aiTipAccent.withAlpha(60),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.aiTipAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.aiTipAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF3730A3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.expressionText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
