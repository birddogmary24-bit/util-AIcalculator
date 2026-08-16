import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';
import 'data/local/app_database.dart';
import 'data/local/database_provider.dart';
import 'domain/services/notification_service.dart';
import 'domain/services/secure_config.dart';

// API key injected via --dart-define=GEMINI_API_KEY=... at build/run time.
// Never hardcoded in source — safe to commit.
const _testApiKey = String.fromEnvironment('GEMINI_API_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if environment variables are provided
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  }

  // Pre-populate API key if provided via dart-define (dev only)
  if (_testApiKey.isNotEmpty) {
    await SecureConfig.setApiKey(_testApiKey);
  }

  // Initialize local notifications (no-op on web)
  await NotificationService.init();

  // Check if onboarding has been completed
  final prefs = await SharedPreferences.getInstance();
  final isOnboarded = prefs.containsKey('region_mode');

  // Open DB — driftDatabase() picks platform executor automatically:
  // web → WasmDatabase (IndexedDB/OPFS, persistent), native → SQLite file
  final db = AppDatabase(driftDatabase(
    name: 'history_db',
    web: kIsWeb
        ? DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          )
        : null,
  ));

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: App(showOnboarding: !isOnboarded),
    ),
  );
}
