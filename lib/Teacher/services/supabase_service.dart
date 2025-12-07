import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static SupabaseClient get client => _client;

  static Future<List<dynamic>> queryTable(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    var query = _client.from(table).select();

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    final response = await query;
    return response as List<dynamic>;
  }

  static Future<dynamic> insertRecord(
    String table,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.from(table).insert(data).select().single();
    return response;
  }

  static Future<dynamic> updateRecord(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from(table)
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return response;
  }
}
