import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../domain/models/button_definition.dart';
import 'calc_button.dart';

/// Special return value indicating "reset to default".
const _resetSentinel = '__RESET__';

/// Shows a bottom sheet with all available buttons grouped by category.
/// Returns the selected button ID, `_resetSentinel` for reset, or null if dismissed.
Future<String?> showButtonSwapModal(
  BuildContext context, {
  required Set<String> currentIds,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ButtonSwapSheet(currentIds: currentIds),
  );
}

/// Whether the returned value is the reset sentinel.
bool isResetResult(String? result) => result == _resetSentinel;

class _ButtonSwapSheet extends StatelessWidget {
  final Set<String> currentIds;
  const _ButtonSwapSheet({required this.currentIds});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '버튼 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable button list
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              shrinkWrap: true,
              children: [
                ...buttonCategories.entries.map((entry) {
                  return _buildSection(context, entry.key, entry.value);
                }),
                const SizedBox(height: 16),
                // Reset button — prominent
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, _resetSentinel),
                    icon: const Icon(Icons.restart_alt, size: 22),
                    label: const Text(
                      '버튼 배치 초기화',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.clearBtn,
                      side: const BorderSide(color: AppColors.clearBtn, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<String> buttonIds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: buttonIds.map((id) {
            final def = getButtonDef(id);
            if (def == null) return const SizedBox.shrink();
            final isUsed = currentIds.contains(id);
            return _buildSelectableButton(context, def, isUsed);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectableButton(
      BuildContext context, CalcButtonDef def, bool isUsed) {
    Color bgColor;
    Color fgColor;

    switch (def.type) {
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

    // Tool/navigate buttons get a distinct style
    final isToolBtn = def.action == ButtonAction.navigate;
    final btnWidth = isToolBtn ? 72.0 : 56.0;
    const btnHeight = 48.0;
    final textSize = isToolBtn ? 13.0 : 18.0;

    return GestureDetector(
      onTap: () => Navigator.pop(context, def.id),
      child: Stack(
        children: [
          Container(
            width: btnWidth,
            height: btnHeight,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF9E9E9E), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  offset: const Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              def.label,
              style: TextStyle(
                color: fgColor,
                fontSize: textSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isUsed)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
