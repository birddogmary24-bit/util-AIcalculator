import 'package:flutter/material.dart';
import '../../../core/constants/region.dart';
import '../../../core/constants/tool_registry.dart';
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
  required RegionMode region,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ButtonSwapSheet(
      currentIds: currentIds,
      region: region,
    ),
  );
}

/// Whether the returned value is the reset sentinel.
bool isResetResult(String? result) => result == _resetSentinel;

class _ButtonSwapSheet extends StatelessWidget {
  final Set<String> currentIds;
  final RegionMode region;

  const _ButtonSwapSheet({
    required this.currentIds,
    required this.region,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(region);
    final maxHeight = MediaQuery.of(context).size.height * 0.65;
    final categories = getButtonCategories(region);

    // Separate tool IDs from other categories
    final toolCategoryKey = s['bcat_tools']!;
    final toolIds = categories[toolCategoryKey] ?? [];
    final nonToolCategories = Map<String, List<String>>.from(categories)
      ..remove(toolCategoryKey);

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
                Expanded(
                  child: Text(
                    s['select_button']!,
                    style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              s['button_swap_hint']!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                height: 1.4,
              ),
            ),
          ),
          const Divider(height: 1),

          // Scrollable content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              shrinkWrap: true,
              children: [
                // Non-tool categories (digits, operators, functions)
                ...nonToolCategories.entries.map((entry) {
                  return _buildSection(context, entry.key, entry.value);
                }),

                // Tools section — 2-column grid with icons
                if (toolIds.isNotEmpty)
                  _buildToolsSection(context, toolCategoryKey, toolIds),
              ],
            ),
          ),

          // Fixed reset button at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, _resetSentinel),
                icon: const Icon(Icons.restart_alt, size: 22),
                label: Text(
                  s['reset_layout']!,
                  style: const TextStyle(
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

  Widget _buildToolsSection(
      BuildContext context, String title, List<String> toolIds) {
    // Map button IDs to tool registry entries for icon/color
    final filteredTools = getFilteredTools(region);
    final toolMap = <String, _ToolInfo>{};
    for (final id in toolIds) {
      final btnDef = getButtonDef(id);
      if (btnDef == null) continue;
      // Find matching tool definition from registry
      final toolId = id.replaceFirst('tool_', '').replaceAll('_', '-');
      final toolDef = filteredTools.where((t) => t.id == toolId).firstOrNull;
      toolMap[id] = _ToolInfo(
        btnDef: btnDef,
        icon: toolDef?.icon ?? Icons.calculate,
        color: toolDef?.color ?? AppColors.primary,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 52,
          ),
          itemCount: toolMap.length,
          itemBuilder: (context, index) {
            final entry = toolMap.entries.elementAt(index);
            final info = entry.value;
            final isUsed = currentIds.contains(entry.key);
            return _buildToolTile(context, entry.key, info, isUsed);
          },
        ),
      ],
    );
  }

  Widget _buildToolTile(
      BuildContext context, String id, _ToolInfo info, bool isUsed) {
    final displayLabel = info.btnDef.localizedLabel(region);

    return GestureDetector(
      onTap: () => Navigator.pop(context, id),
      child: Container(
        decoration: BoxDecoration(
          color: isUsed
              ? AppColors.primary.withAlpha(15)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUsed ? AppColors.primary.withAlpha(100) : const Color(0xFFE0E0E0),
            width: isUsed ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: info.color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(info.icon, color: info.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isUsed ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isUsed)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 11, color: Colors.white),
              ),
          ],
        ),
      ),
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

    final displayLabel = def.localizedLabel(region);

    return GestureDetector(
      onTap: () => Navigator.pop(context, def.id),
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 48,
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
              displayLabel,
              style: TextStyle(
                color: fgColor,
                fontSize: 18,
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

class _ToolInfo {
  final CalcButtonDef btnDef;
  final IconData icon;
  final Color color;

  const _ToolInfo({
    required this.btnDef,
    required this.icon,
    required this.color,
  });
}
