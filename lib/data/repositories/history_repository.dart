import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory history repository.
/// Drift DB로 교체될 예정 — 현재는 웹에서 바로 실행되도록 메모리 기반으로 구현.
class HistoryEntry {
  final int id;
  final String expression;
  final double result;
  final String source;
  String? aiLabel;
  final DateTime createdAt;

  HistoryEntry({
    required this.id,
    required this.expression,
    required this.result,
    required this.source,
    this.aiLabel,
    required this.createdAt,
  });
}

class HistoryRepository {
  final List<HistoryEntry> _entries = [];
  int _nextId = 1;

  List<HistoryEntry> get all =>
      List.unmodifiable(_entries.reversed.toList());

  void save({
    required String expression,
    required double result,
    required String source,
  }) {
    _entries.add(HistoryEntry(
      id: _nextId++,
      expression: expression,
      result: result,
      source: source,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> updateLatestLabel(String label) async {
    if (_entries.isEmpty) return;
    _entries.last.aiLabel = label;
  }

  Future<void> updateLabel(int id, String label) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx != -1) _entries[idx].aiLabel = label;
  }

  void delete(int id) {
    _entries.removeWhere((e) => e.id == id);
  }

  void clearAll() {
    _entries.clear();
  }

  List<HistoryEntry> search(String query) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return _entries.reversed
        .where((e) =>
            e.expression.toLowerCase().contains(q) ||
            (e.aiLabel?.toLowerCase().contains(q) ?? false) ||
            e.result.toString().contains(q))
        .toList();
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

// Notifier so UI can reactively update when history changes
final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEntry>>((ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});

class HistoryNotifier extends StateNotifier<List<HistoryEntry>> {
  final HistoryRepository _repo;

  HistoryNotifier(this._repo) : super([]);

  void refresh() {
    state = List.from(_repo.all);
  }

  void delete(int id) {
    _repo.delete(id);
    refresh();
  }

  void clearAll() {
    _repo.clearAll();
    state = [];
  }

  List<HistoryEntry> search(String query) => _repo.search(query);
}
