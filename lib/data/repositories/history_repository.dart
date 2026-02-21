import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/app_database.dart';
import '../local/database_provider.dart';

// Re-export Drift-generated HistoryEntry so UI/providers keep the same import.
export '../local/app_database.dart' show HistoryEntry;

// Extension: createdAt getter used by history_screen.dart
extension HistoryEntryDate on HistoryEntry {
  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMs);
}

class HistoryRepository {
  final AppDatabase _db;

  HistoryRepository(this._db);

  Future<List<HistoryEntry>> get all async {
    return (_db.select(_db.historyEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  Future<void> save({
    required String expression,
    required double result,
    required String source,
  }) async {
    await _db.into(_db.historyEntries).insert(HistoryEntriesCompanion.insert(
          expression: expression,
          result: result,
          source: source,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ));
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.historyEntries)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> clearAll() async {
    await _db.delete(_db.historyEntries).go();
  }

  Future<List<HistoryEntry>> search(String query) async {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    final entries = await all;
    return entries
        .where((e) =>
            e.expression.toLowerCase().contains(q) ||
            e.result.toString().contains(q))
        .toList();
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(appDatabaseProvider));
});

// Notifier so UI can reactively update when history changes
final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEntry>>((ref) {
  return HistoryNotifier(ref.watch(historyRepositoryProvider));
});

class HistoryNotifier extends StateNotifier<List<HistoryEntry>> {
  final HistoryRepository _repo;

  HistoryNotifier(this._repo) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repo.all;
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await refresh();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
  }

  Future<List<HistoryEntry>> search(String query) => _repo.search(query);
}
