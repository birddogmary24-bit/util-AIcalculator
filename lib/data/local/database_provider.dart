import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Overridden in main.dart with a platform-specific QueryExecutor.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in main()');
});
