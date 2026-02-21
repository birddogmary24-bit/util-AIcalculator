import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/region.dart';
import '../../core/constants/tool_registry.dart';
import '../../domain/models/tool_definition.dart';
import '../../providers/region_provider.dart';

class ToolsMenuScreen extends ConsumerWidget {
  const ToolsMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = ref.watch(regionProvider);
    final s = AppStrings.of(region);
    final cs = Theme.of(context).colorScheme;

    // Get region-filtered tools and localized categories
    final filteredTools = getFilteredTools(region);
    final localizedCategories = getToolCategories(region);

    // Group tools by localized category, preserving order
    final grouped = <String, List<ToolDefinition>>{};
    for (final cat in localizedCategories) {
      final items = filteredTools
          .where((t) => t.localizedCategory(region) == cat)
          .toList();
      if (items.isNotEmpty) grouped[cat] = items;
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          s['tools_title']!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 4, left: 4),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            ...entry.value.map(
              (tool) => _ToolListItem(
                tool: tool,
                region: region,
                onTap: () => context.push('/tools/${tool.routePath}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolListItem extends StatelessWidget {
  final ToolDefinition tool;
  final RegionMode region;
  final VoidCallback onTap;

  const _ToolListItem({
    required this.tool,
    required this.region,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(tool.icon, color: tool.color, size: 28),
            const SizedBox(width: 14),
            Text(
              tool.localizedLabel(region),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
