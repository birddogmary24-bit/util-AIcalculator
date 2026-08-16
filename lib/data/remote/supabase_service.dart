import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient? get client {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isAvailable => client != null;

  /// Save calculation record to Supabase
  static Future<void> saveCalculation({
    required String expression,
    required double result,
    required String source,
    required DateTime createdAt,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      await client.from('calculations').insert({
        'expression': expression,
        'result': result.toString(),
        'source': source,
        'created_at': createdAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] saveCalculation failed: $e');
    }
  }

  /// Fetch recent calculations from Supabase
  static Future<List<Map<String, dynamic>>> fetchCalculations({
    int limit = 50,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return [];

    try {
      final response = await client
          .from('calculations')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[SupabaseService] fetchCalculations failed: $e');
      return [];
    }
  }

  /// Delete all calculation records in Supabase
  static Future<void> clearAllCalculations() async {
    final client = SupabaseService.client;
    if (client == null) return;

    try {
      await client.from('calculations').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    } catch (e) {
      debugPrint('[SupabaseService] clearAllCalculations failed: $e');
    }
  }
}
