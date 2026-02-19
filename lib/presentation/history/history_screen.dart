import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/repositories/history_repository.dart';
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return '오늘';
    if (date == today.subtract(const Duration(days: 1))) return '어제';
    return DateFormat('M월 d일', 'ko').format(dt);
  }

  String _formatTime(DateTime dt) => DateFormat('a h:mm', 'ko').format(dt);

  @override
  Widget build(BuildContext context) {
    final historyNotifier = ref.watch(historyNotifierProvider.notifier);
    final allEntries = _query.isEmpty
        ? ref.watch(historyNotifierProvider)
        : historyNotifier.search(_query);

    // Group by date
    final Map<String, List<HistoryEntry>> grouped = {};
    for (final entry in allEntries) {
      final key = _formatDate(entry.createdAt);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '계산 기록',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (allEntries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '전체 삭제',
              onPressed: () => _confirmClearAll(context),
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
                hintText: '기록 검색 (레이블, 숫자)',
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
                ? _EmptyState(hasQuery: _query.isNotEmpty)
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
                                formatTime: _formatTime,
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

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('모든 계산 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(historyNotifierProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('삭제'),
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
                    if (entry.aiLabel != null)
                      Text(
                        entry.aiLabel!,
                        style: TextStyle(
                          color: _sourceColor(entry.source),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
  const _EmptyState({required this.hasQuery});

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
            hasQuery ? '검색 결과가 없습니다' : '아직 계산 기록이 없습니다',
            style: const TextStyle(
              color: AppColors.expressionText,
              fontSize: 16,
            ),
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 8),
            const Text(
              '계산기 탭에서 계산하면\n자동으로 저장됩니다',
              textAlign: TextAlign.center,
              style: TextStyle(
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
