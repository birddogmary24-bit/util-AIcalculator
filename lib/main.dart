import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'domain/services/secure_config.dart';

// API key injected via --dart-define=GEMINI_API_KEY=... at build/run time.
// Never hardcoded in source — safe to commit.
const _testApiKey = String.fromEnvironment('GEMINI_API_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-populate API key if provided via dart-define (test/dev only)
  if (_testApiKey.isNotEmpty) {
    await SecureConfig.setApiKey(_testApiKey);
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
