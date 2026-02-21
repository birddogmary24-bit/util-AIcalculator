import 'package:drift/drift.dart';

part 'app_database.g.dart';

class HistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get expression => text()();
  RealColumn get result => real()();
  TextColumn get source => text()();
  IntColumn get createdAtMs => integer()();
}

@DriftDatabase(tables: [HistoryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
