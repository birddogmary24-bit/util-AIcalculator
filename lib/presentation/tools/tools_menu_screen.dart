import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/tool_registry.dart';
import '../../domain/models/tool_definition.dart';

class ToolsMenuScreen extends StatelessWidget {
  const ToolsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Group tools by category, preserving toolCategories order
    final grouped = <String, List<ToolDefinition>>{};
    for (final cat in toolCategories) {
      final items = toolRegistry.where((t) => t.category == cat).toList();
      if (items.isNotEmpty) grouped[cat] = items;
    }

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text(
          '계산기 더보기',
          style: TextStyle(fontWeight: FontWeight.w600),
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
  final VoidCallback onTap;

  const _ToolListItem({required this.tool, required this.onTap});

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
              tool.label,
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
