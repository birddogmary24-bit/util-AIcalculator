import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/region.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/repositories/history_repository.dart';
import '../../providers/region_provider.dart';
import '../calculator/calculator_provider.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt, RegionMode region, Map<String, String> s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return s['today']!;
    if (date == today.subtract(const Duration(days: 1))) return s['yesterday']!;
    return region == RegionMode.kr
        ? DateFormat('M월 d일', 'ko').format(dt)
        : DateFormat('MMM d', 'en').format(dt);
  }

  String _formatTime(DateTime dt, RegionMode region) {
    return region == RegionMode.kr
        ? DateFormat('a h:mm', 'ko').format(dt)
        : DateFormat('h:mm a', 'en').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final region = ref.watch(regionProvider);
    final s = AppStrings.of(region);
    final allHistory = ref.watch(historyNotifierProvider);
    final allEntries = _query.isEmpty
        ? allHistory
        : allHistory
            .where((e) =>
                e.expression.toLowerCase().contains(_query.toLowerCase()) ||
                e.result.toString().contains(_query))
            .toList();

    // Group by date
    final Map<String, List<HistoryEntry>> grouped = {};
    for (final entry in allEntries) {
      final key = _formatDate(entry.createdAt, region, s);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s['calc_history']!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (allEntries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: s['delete_all']!,
              onPressed: () => _confirmClearAll(context, s),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: s['search_hint']!,
                hintStyle: const TextStyle(
                  color: AppColors.expressionText,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.expressionText,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          // List
          Expanded(
            child: allEntries.isEmpty
                ? _EmptyState(
                    hasQuery: _query.isNotEmpty,
                    noResultsText: s['no_results']!,
                    noHistoryText: s['no_history']!,
                    autoSaveHintText: s['auto_save_hint']!,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, groupIdx) {
                      final dateKey = grouped.keys.elementAt(groupIdx);
                      final entries = grouped[dateKey]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                            child: Text(
                              dateKey,
                              style: const TextStyle(
                                color: AppColors.expressionText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ...entries.map((e) => _HistoryTile(
                                entry: e,
                                formatTime: (dt) =>
                                    _formatTime(dt, region),
                                onTap: () {
                                  ref
                                      .read(calculatorProvider.notifier)
                                      .loadFromHistory(
                                          e.expression, e.result);
                                  context.go('/');
                                },
                                onDelete: () => ref
                                    .read(historyNotifierProvider.notifier)
                                    .delete(e.id),
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, Map<String, String> s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['confirm_delete_all_title']!),
        content: Text(s['confirm_delete_all']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s['cancel']!),
          ),
          FilledButton(
            onPressed: () {
              ref.read(historyNotifierProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: Text(s['delete']!),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final String Function(DateTime) formatTime;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.formatTime,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Source icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _sourceColor(entry.source).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _sourceIcon(entry.source),
                  size: 18,
                  color: _sourceColor(entry.source),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.expression.isNotEmpty
                          ? entry.expression
                          : NumberFormatter.format(entry.result),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '= ${NumberFormatter.format(entry.result)}',
                      style: const TextStyle(
                        color: AppColors.expressionText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Time + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatTime(entry.createdAt),
                    style: const TextStyle(
                      color: AppColors.expressionText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.expressionText,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _sourceColor(String source) {
    switch (source) {
      case 'nlp':
        return AppColors.primary;
      case 'ocr':
        return AppColors.success;
      default:
        return AppColors.expressionText;
    }
  }

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'nlp':
        return Icons.auto_awesome_outlined;
      case 'ocr':
        return Icons.receipt_long_outlined;
      default:
        return Icons.calculate_outlined;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  final String noResultsText;
  final String noHistoryText;
  final String autoSaveHintText;

  const _EmptyState({
    required this.hasQuery,
    required this.noResultsText,
    required this.noHistoryText,
    required this.autoSaveHintText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off : Icons.history,
            size: 64,
            color: AppColors.expressionText,
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? noResultsText : noHistoryText,
            style: const TextStyle(
              color: AppColors.expressionText,
              fontSize: 16,
            ),
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 8),
            Text(
              autoSaveHintText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.expressionText,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
